#==============================================================================#
#                                                                              #
#  Copyright (c) 2012 MaidSafe.net limited                                     #
#                                                                              #
#  The following source code is property of MaidSafe.net limited and is not    #
#  meant for external use.  The use of this code is governed by the license    #
#  file licence.txt found in the root directory of this project and also on    #
#  www.maidsafe.net.                                                           #
#                                                                              #
#  You are not free to copy, amend or otherwise use this source code without   #
#  the explicit written permission of the board of directors of MaidSafe.net.  #
#                                                                              #
#==============================================================================#
#                                                                              #
#  Uses built in CMake module FindQt4 to locate QT libs and headers.  This     #
#  FindQt4 module requires that the Qt4 qmake executable is available via the  #
#  system path.  If this is the case, then the module sets the variable        #
#  QT_USE_FILE which is the path to a CMake file that is included in order to  #
#  compile Qt 4 applications and libraries. It sets up the compilation         #
#  environment for include directories, preprocessor defines and populates a   #
#  QT_LIBRARIES variable.                                                      #
#                                                                              #
#  If Qt needs to be built first, set BUILD_QT=ON                              #
#                                                                              #
#  Settable variable to aid with finding Qt is QT_SRC_DIR                      #
#                                                                              #
#  Since this module uses the option to include(${QT_USE_FILE}), the           #
#  compilation environment is automatically set up with include directories    #
#  and preprocessor definitions.  The requested Qt libs are set up as targets, #
#  e.g. QT_QTCORE_LIBRARY.  All libs are added to the variable QT_LIBRARIES.   #
#  See documentation of FindQt4 for further info.                              #
#                                                                              #
#==============================================================================#


unset(QT_QMAKE_EXECUTABLE CACHE)
unset(QT_LIBRARIES CACHE)
unset(QT_LIBRARY_DIR CACHE)
unset(QT_MOC_EXECUTABLE CACHE)
unset(QT_INCLUDE_DIR CACHE)
unset(QT_INCLUDES CACHE)


set(QT_ERROR_MESSAGE "\nYou can download Qt at http://qt.nokia.com/downloads\n\n")
set(QT_ERROR_MESSAGE "${QT_ERROR_MESSAGE}If Qt is already installed, run:\n")
set(QT_ERROR_MESSAGE "${QT_ERROR_MESSAGE}   cmake . -DQT_SRC_DIR=<Path to Qt source directory>")
if(WIN32)
  set(QT_ERROR_MESSAGE "${QT_ERROR_MESSAGE}\n(such that qmake.exe is in \"<Path to Qt source directory>\\bin\").")
else()
  set(QT_ERROR_MESSAGE "${QT_ERROR_MESSAGE}\n(such that qmake is in \"<Path to Qt source directory>/bin\").")
endif()
set(QT_ERROR_MESSAGE "${QT_ERROR_MESSAGE}\n\nIf Qt is downloaded, but not built, run:\n")
set(QT_ERROR_MESSAGE "${QT_ERROR_MESSAGE}   cmake . -DBUILD_QT=ON -DQT_SRC_DIR=<Path to Qt source directory>\n\nor\n\n")
set(QT_ERROR_MESSAGE "${QT_ERROR_MESSAGE}   cmake . -DBUILD_QT_IN_SOURCE=ON -DQT_SRC_DIR=<Path to Qt source directory>\n\n")


set(QT_USE_IMPORTED_TARGETS FALSE)
if(BUILD_QT OR BUILD_QT_IN_SOURCE)
  # Clean out old Qt dlls from binary directory
  file(GLOB QtReleaseDlls "${CMAKE_BINARY_DIR}/Release/q*.dll")
  file(GLOB QtDebugDlls "${CMAKE_BINARY_DIR}/Debug/q*.dll")
  if(QtReleaseDlls OR QtDebugDlls)
    file(REMOVE ${QtReleaseDlls} ${QtDebugDlls})
  endif()
  include(${CMAKE_SOURCE_DIR}/cmake_modules/maidsafe_build_qt4.cmake)
elseif(QT_SRC_DIR)
  set(QT_ROOT_DIR ${QT_SRC_DIR} CACHE PATH "Path to Qt source and built libraries' root directory" FORCE)
  unset(QT_SRC_DIR CACHE)
endif()


set(ENV{QTDIR} ${QT_ROOT_DIR})
find_program(QT_QMAKE_EXECUTABLE NAMES qmake qmake4 qmake-qt4 PATHS ${QT_ROOT_DIR}/bin NO_DEFAULT_PATH)
find_program(QT_QMAKE_EXECUTABLE NAMES qmake qmake4 qmake-qt4 PATHS ${QT_ROOT_DIR}/bin)
if(NOT QT_QMAKE_EXECUTABLE)
  set(ERROR_MESSAGE "\nCould not find Qt.  NO QMAKE EXECUTABLE.")
  if(WIN32)
    set(ERROR_MESSAGE "${ERROR_MESSAGE}(Tried to find qmake.exe in ${QT_ROOT_DIR}\\bin and the system path.)")
  else()
    set(ERROR_MESSAGE "${ERROR_MESSAGE}(Tried to find qmake in ${QT_ROOT_DIR}/bin and the system path.)")
  endif()
  message(FATAL_ERROR "${ERROR_MESSAGE}${QT_ERROR_MESSAGE}")
endif()


set(MS_QT_REQUIRED_LIBRARIES QtCore QtGui QtXml QtSql QtWebKit)
if(WIN32)
  set(MS_QT_REQUIRED_LIBRARIES ${MS_QT_REQUIRED_LIBRARIES} QtMain)
endif()
find_package(Qt4 4.8.2 COMPONENTS ${MS_QT_REQUIRED_LIBRARIES} REQUIRED)
include(${QT_USE_FILE})


set(ALL_QT_LIBRARIES_FOUND 1)
foreach(MS_QT_REQUIRED_LIBRARY ${MS_QT_REQUIRED_LIBRARIES})
  string(TOUPPER ${MS_QT_REQUIRED_LIBRARY} MS_QT_REQUIRED_LIBRARY)
  if(NOT QT_${MS_QT_REQUIRED_LIBRARY}_FOUND)
    set(ERROR_MESSAGE "${ERROR_MESSAGE}Could not find ${MS_QT_REQUIRED_LIBRARY}\n")
    set(ALL_QT_LIBRARIES_FOUND 0)
  endif()
endforeach()
if(NOT ALL_QT_LIBRARIES_FOUND)
  message(FATAL_ERROR "${ERROR_MESSAGE}${QT_ERROR_MESSAGE}")
endif()


# Copy dlls to binary directory
if(WIN32)
  file(GLOB QtImageFormatsPluginsRelease "${QT_ROOT_DIR}/plugins/imageformats/*.dll")
  file(GLOB QtImageFormatsPluginsDebug "${QT_ROOT_DIR}/plugins/imageformats/*d4.dll")
  if(QtImageFormatsPluginsRelease)
    list(REMOVE_ITEM QtImageFormatsPluginsRelease ${QtImageFormatsPluginsDebug})
  endif()
  file(GLOB QtLibsRelease "${QT_ROOT_DIR}/bin/*.dll")
  file(GLOB QtLibsDebug "${QT_ROOT_DIR}/bin/*d4.dll")
  if(QtLibsRelease)
    list(REMOVE_ITEM QtLibsRelease ${QtLibsDebug})
  endif()
  execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/Release")
  execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/Debug")
  foreach(QtReleaseDll ${QtLibsRelease} ${QtImageFormatsPluginsRelease})
    execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different "${QtReleaseDll}" "${CMAKE_BINARY_DIR}/Release")
  endforeach()
  foreach(QtDebugDll ${QtLibsDebug} ${QtImageFormatsPluginsDebug})
    execute_process(COMMAND ${CMAKE_COMMAND} -E copy_if_different "${QtDebugDll}" "${CMAKE_BINARY_DIR}/Debug")
  endforeach()
endif()

# Re-include Qt dirs using -isystem to override the -I applied by "include(${QT_USE_FILE})" above.
if(NOT WIN32)
  include_directories(SYSTEM ${QT_QTCORE_INCLUDE_DIR}
                             ${QT_QTGUI_INCLUDE_DIR}
                             ${QT_QTWEBKIT_INCLUDE_DIR}
                             ${QT_QTSQL_INCLUDE_DIR}
                             ${QT_QTXML_INCLUDE_DIR}
                             ${QT_INCLUDE_DIR})
endif()

function(maidsafe_qt4_wrap_ui UIC_FILES_OUT UIC_FILES_IN)
  set(COMPILED_UI_FILES_DIR ${CMAKE_CURRENT_BINARY_DIR}/compiled_ui_files)
  file(MAKE_DIRECTORY ${COMPILED_UI_FILES_DIR})
  set(CMAKE_CURRENT_BINARY_DIR_BEFORE ${CMAKE_CURRENT_BINARY_DIR})
  set(CMAKE_CURRENT_BINARY_DIR ${COMPILED_UI_FILES_DIR})
  QT4_WRAP_UI(${UIC_FILES_OUT} ${${UIC_FILES_IN}})
  include_directories(BEFORE SYSTEM ${COMPILED_UI_FILES_DIR})
  set(${UIC_FILES_OUT} ${${UIC_FILES_OUT}} PARENT_SCOPE)
  set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR_BEFORE})
endfunction()