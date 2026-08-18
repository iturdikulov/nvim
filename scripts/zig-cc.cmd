@echo off
if "%ZIG_CC_TARGET%"=="" set ZIG_CC_TARGET=x86_64-windows-gnu
zig cc %* -target %ZIG_CC_TARGET%
