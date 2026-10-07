# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Release")
  file(REMOVE_RECURSE
  "CMakeFiles/edot-browser_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/edot-browser_autogen.dir/ParseCache.txt"
  "edot-browser_autogen"
  )
endif()
