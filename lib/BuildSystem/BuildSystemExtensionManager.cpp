//===-- BuildSystemExtensionManager.cpp -----------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#include "llbuild/BuildSystem/BuildSystemExtensions.h"

#include "llbuild/Basic/Subprocess.h"

#include "llvm/Support/FileSystem.h"
#include "llvm/Support/raw_ostream.h"

#if defined(__unix__) || (defined(__APPLE__) && defined(__MACH__))
#include <dlfcn.h>
#endif

using namespace llbuild;
using namespace llbuild::basic;
using namespace llbuild::buildsystem;

HandlerState::~HandlerState() {}
ShellCommandHandler::~ShellCommandHandler() {}
BuildSystemExtension::~BuildSystemExtension() {}

#pragma mark - BuildSystemExtensionManager implementation

BuildSystemExtension*
BuildSystemExtensionManager::lookupByCommandPath(StringRef path) {
  std::lock_guard<std::mutex> guard(extensionsLock);

  // Check the cache.
  auto it = extensions.find(path);
  if (it != extensions.end()) return it->second.get();

  // Register negative hit, unless we succeed.
  extensions[path] = nullptr;

  // If missing, look for an extension for this path.
  //
  // Currently, extensions are discovered by expecting that a command has an
  // adjacent "...-for-llbuild" binary which can be queried for info.
  SmallString<256> infoPath{ path };
  infoPath += "-for-llbuild";
  if (!llvm::sys::fs::exists(infoPath)) {
    return {};
  }

  // If the path exists, then query it to find the actual extension library.
  struct CapturingProcessDelegate: ProcessDelegate {
    SmallString<1024> output;
    bool success;
    
    virtual void processStarted(ProcessContext* ctx, ProcessHandle handle) {}

    virtual void processHadError(ProcessContext* ctx, ProcessHandle handle,
                                 const Twine& message) {};

    virtual void processHadOutput(ProcessContext* ctx, ProcessHandle handle,
                                  StringRef data) {
      output += data;
    };

    virtual void processFinished(ProcessContext* ctx, ProcessHandle handle,
                                 const ProcessResult& result) {
      success = (result.status == ProcessStatus::Succeeded &&
                 result.exitCode == 0);
    }
  };
  CapturingProcessDelegate delegate;
  {
    // FIXME: Add a utility for capturing a subprocess infocation.
    ProcessAttributes attr{/*canSafelyInterrupt=*/true};
    ProcessGroup pgrp;
    ProcessHandle handle{0};
    std::vector<StringRef> cmd{infoPath, "--llbuild-extension-version", "0",
        "--extension-path" };
    ProcessReleaseFn releaseFn = [](std::function<void()>&& pwait){ pwait(); };
    ProcessCompletionFn completionFn = [](ProcessResult){};
    spawnProcess(delegate, nullptr, pgrp, handle, cmd, POSIXEnvironment(), attr,
                 std::move(releaseFn), std::move(completionFn));
  }

  // The output is expected to be the exact path to the extension (no extra
  // whitespace, etc.).
  auto extensionPath = delegate.output;
  if (!delegate.success || !llvm::sys::fs::exists(infoPath)) {
    return {};
  }

#if defined(__unix__) || (defined(__APPLE__) && defined(__MACH__))
  // Load the plugin.
  auto handle = dlopen(extensionPath.c_str(), RTLD_LAZY);
  if (!handle) {
    return {};
  }

  auto registrationFn = (BuildSystemExtension*(*)(void)) dlsym(
      handle, "initialize_llbuild_buildsystem_extension_v0");
  if (!registrationFn) {
    dlclose(handle);
    return {};
  }

  // For now, we expect the registration to simply allocate and return us a (C)
  // extension instance.
  //
  // FIXME: This needs to be reworked to go through a C API.
  auto *extension = registrationFn();
  if (!extension) {
    dlclose(handle);
    return {};
  }
#else
  HMODULE hModule = LoadLibraryA(extensionPath.c_str());
  if (hModule == NULL) {
    return {};
  }

  BuildSystemExtension *(*registrationFn)(void) =
      reinterpret_cast<decltype(registrationFn)>(GetProcAddress(hModule,
                                                                "initialize_llbuild_buildsystem_extension_v0"));
  if (!registrationFn) {
    FreeLibrary(hModule);
    return {};
  }

  BuildSystemExtension *extension = registrationFn();
  if (!extension) {
    FreeLibrary(hModule);
    return {};
  }
#endif

  extensions[path] = std::unique_ptr<BuildSystemExtension>(extension);
  return extension;
}

