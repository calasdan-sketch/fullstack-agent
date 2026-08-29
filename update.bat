@echo off
rem fullstack-agent: give your AI a full stack. memory, voice, face, hands.
rem Copyright (C) 2026 Jared Rhodenizer
rem
rem This program is free software: you can redistribute it and/or modify
rem it under the terms of the GNU Affero General Public License as published
rem by the Free Software Foundation, either version 3 of the License, or
rem (at your option) any later version.
rem
rem This program is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
rem GNU Affero General Public License for more details.
rem
rem You should have received a copy of the GNU Affero General Public License
rem along with this program. If not, see <https://www.gnu.org/licenses/>.
rem
rem SPDX-License-Identifier: AGPL-3.0-or-later

rem Pulls the newest version of every installed piece, and of this repo.
rem Your files live outside the repos, so updates never touch them. If git
rem reports a conflict on a config you edited, your edit wins.

rem NO SELF-RELAUNCH, and the reason is worth keeping.
rem
rem cmd reads a .bat by byte offset, so a script that pulls a new copy of
rem ITSELF mid-run can garble from that point on. This used to guard against
rem that by copying itself into LOCALAPPDATA and running the copy.
rem
rem Copying yourself somewhere and running the copy is a shape security
rem software is built to distrust, and it cannot see why you did it. On
rem some machines that stopped the install outright: the scanner held this
rem file open and the unpack could not write it.
rem
rem The guard was never worth that. It only mattered on an update that
rem changed this very script, and by then the pull had already succeeded.
rem The worst case now is an odd looking line at the very end. If you ever
rem see one, just run this again.


setlocal
cd /d "%~dp0.."
for %%r in (fullstack-agent ai-memory-vault backtalk barehands ai-visualizer) do (
  if exist "%%r\.git\" call :one "%%r"
)
echo update complete.
if not exist "%USERPROFILE%\Desktop\Update *" echo Tip: want a desktop Update icon that does this on a double-click? Open your agent and ask for one.
exit /b 0

:one
echo == %~1
rem show what is arriving BEFORE applying it
git -C "%~1" fetch -q origin 2>nul
git -C "%~1" log --oneline "..@{u}" 2>nul
rem one-time migration (2026-08): the per-piece configs moved out of git
rem tracking so an update can never collide with personal settings. If
rem this clone still tracks one, lift it aside, pull, put it back as-is.
set CFG=
if "%~1"=="backtalk" set CFG=backtalk.json
if "%~1"=="barehands" set CFG=barehands.json
if "%~1"=="ai-visualizer" set CFG=ai-visualizer.json
set MIGRATE=0
if not defined CFG goto pull
if not exist "%~1\%CFG%" goto pull
git -C "%~1" ls-files --error-unmatch "%CFG%" >nul 2>nul
if errorlevel 1 goto pull
copy /y "%~1\%CFG%" "%~1\%CFG%.mine" >nul
git -C "%~1" checkout -- "%CFG%"
set MIGRATE=1
:pull
git -C "%~1" pull --ff-only
if "%MIGRATE%"=="1" if exist "%~1\%CFG%.mine" move /y "%~1\%CFG%.mine" "%~1\%CFG%" >nul
exit /b 0
