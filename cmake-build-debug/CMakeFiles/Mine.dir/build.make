# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.19

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Disable VCS-based implicit rules.
% : %,v


# Disable VCS-based implicit rules.
% : RCS/%


# Disable VCS-based implicit rules.
% : RCS/%,v


# Disable VCS-based implicit rules.
% : SCCS/s.%


# Disable VCS-based implicit rules.
% : s.%


.SUFFIXES: .hpux_make_needs_suffix_list


# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /snap/clion/152/bin/cmake/linux/bin/cmake

# The command to remove a file.
RM = /snap/clion/152/bin/cmake/linux/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine"

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/cmake-build-debug"

# Include any dependencies generated for this target.
include CMakeFiles/Mine.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/Mine.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/Mine.dir/flags.make

CMakeFiles/Mine.dir/main.cpp.o: CMakeFiles/Mine.dir/flags.make
CMakeFiles/Mine.dir/main.cpp.o: ../main.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir="/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/cmake-build-debug/CMakeFiles" --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/Mine.dir/main.cpp.o"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Mine.dir/main.cpp.o -c "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/main.cpp"

CMakeFiles/Mine.dir/main.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Mine.dir/main.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/main.cpp" > CMakeFiles/Mine.dir/main.cpp.i

CMakeFiles/Mine.dir/main.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Mine.dir/main.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/main.cpp" -o CMakeFiles/Mine.dir/main.cpp.s

# Object files for target Mine
Mine_OBJECTS = \
"CMakeFiles/Mine.dir/main.cpp.o"

# External object files for target Mine
Mine_EXTERNAL_OBJECTS =

Mine: CMakeFiles/Mine.dir/main.cpp.o
Mine: CMakeFiles/Mine.dir/build.make
Mine: CMakeFiles/Mine.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir="/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/cmake-build-debug/CMakeFiles" --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable Mine"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/Mine.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/Mine.dir/build: Mine

.PHONY : CMakeFiles/Mine.dir/build

CMakeFiles/Mine.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/Mine.dir/cmake_clean.cmake
.PHONY : CMakeFiles/Mine.dir/clean

CMakeFiles/Mine.dir/depend:
	cd "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/cmake-build-debug" && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine" "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine" "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/cmake-build-debug" "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/cmake-build-debug" "/home/fahim_hakim_15/L-3 T-1/CSE310/004 Intermediate Code Generation/Mine/cmake-build-debug/CMakeFiles/Mine.dir/DependInfo.cmake" --color=$(COLOR)
.PHONY : CMakeFiles/Mine.dir/depend
