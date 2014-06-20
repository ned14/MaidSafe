#==================================================================================================#
#                                                                                                  #
#  Copyright 2012 MaidSafe.net limited                                                             #
#                                                                                                  #
#  This MaidSafe Software is licensed to you under (1) the MaidSafe.net Commercial License,        #
#  version 1.0 or later, or (2) The General Public License (GPL), version 3, depending on which    #
#  licence you accepted on initial access to the Software (the "Licences").                        #
#                                                                                                  #
#  By contributing code to the MaidSafe Software, or to this project generally, you agree to be    #
#  bound by the terms of the MaidSafe Contributor Agreement, version 1.0, found in the root        #
#  directory of this project at LICENSE, COPYING and CONTRIBUTOR respectively and also available   #
#  at: http://www.maidsafe.net/licenses                                                            #
#                                                                                                  #
#  Unless required by applicable law or agreed to in writing, the MaidSafe Software distributed    #
#  under the GPL Licence is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF   #
#  ANY KIND, either express or implied.                                                            #
#                                                                                                  #
#  See the Licences for the specific language governing permissions and limitations relating to    #
#  use of the MaidSafe Software.                                                                   #
#                                                                                                  #
#==================================================================================================#
#                                                                                                  #
#  For a test target named TESTstuff, the module is invoked by calling ms_add_gtests(TESTstuff)    #
#                                                                                                  #
#  This module adds individual gtests by parsing the tests files at a very basic level (e.g.       #
#  there is no support for namespaces).  It also currently doesn't support all gtest options       #
#  (e.g. the only value parameter generators supported are "Range(begin, end[, step])",            #
#  "Values(v1, v2, ..., vN)" and "Bool()").                                                        #
#                                                                                                  #
#  There is basic support for TEST(...), TEST_F(...), TEST_P(...), TYPED_TEST(...) and             #
#  TYPED_TEST_P(...).                                                                              #
#                                                                                                  #
#  There is also support for the MaidSafe macro style of                                           #
#  TEST_MS_NET(fixture_name, test_type(FUNC or BEH), general_name, test_name)                      #
#                                                                                                  #
#  All test names should be of the form "BEH_..." or "FUNC_..." (with an optional "DISABLED_"      #
#  prepended.  Tests named BEH_ will be treated as behavioural tests and will have a CTest         #
#  timeout of BEHAVIOURAL_TEST_TIMEOUT which can be set before invoking this module, or will       #
#  default to 60s.  Tests named FUNC_ will be treated as functional tests and will have a CTest    #
#  timeout of FUNCTIONAL_TEST_TIMEOUT which can also be set externally, or will default to 600s.   #
#                                                                                                  #
#  If 'GlobalTestTimeoutFactor' is defined, all timeouts are multiplied by this value.             #
#                                                                                                  #
#  The variable MAIDSAFE_TEST_TYPE can be set to control which test types will be added; BEH for   #
#  behavioural, FUNC for functional, and anything else for all types.                              #
#                                                                                                  #
#  If the test executables have postfixes included in their names, the variable TEST_POSTFIX       #
#  should be set appropriately.                                                                    #
#                                                                                                  #
#  Individual tests to be excluded should have their full test name included in the variable       #
#  EXCLUDED_TESTS.                                                                                 #
#                                                                                                  #
#  The variable ALL_GTESTS will maintain a list of all tests added via this module.                #
#                                                                                                  #
#==================================================================================================#


# Main function - the only one designed to be called from outside this module.
function(ms_add_gtests TEST_TARGET)
  target_compile_definitions(${TEST_TARGET} PRIVATE USE_GTEST)
  target_link_libraries(${TEST_TARGET} gmock gtest)

  if(NOT BEHAVIOURAL_TEST_TIMEOUT)
    set(BEHAVIOURAL_TEST_TIMEOUT 60)
  endif()
  if(NOT FUNCTIONAL_TEST_TIMEOUT)
    set(FUNCTIONAL_TEST_TIMEOUT 600)
  endif()

  get_target_property(GTEST_SOURCE_FILES ${TEST_TARGET} SOURCES)

  foreach(GTEST_SOURCE_FILE ${GTEST_SOURCE_FILES})
    get_gtest_typedef_types(${GTEST_SOURCE_FILE})
  endforeach()

  foreach(GTEST_SOURCE_FILE ${GTEST_SOURCE_FILES})
    get_gtest_fixtures_types(${GTEST_SOURCE_FILE})
    get_gtest_fixtures_value_parameters(${GTEST_SOURCE_FILE})
    get_gtest_fixtures_type_parameters(${GTEST_SOURCE_FILE})
  endforeach()

  foreach(GTEST_SOURCE_FILE ${GTEST_SOURCE_FILES})
    add_gtest_registered_typed_tests(${GTEST_SOURCE_FILE} ${TEST_TARGET})
    add_gtest_non_type_parameterised(${GTEST_SOURCE_FILE} ${TEST_TARGET})
  endforeach()
  set(ALL_GTESTS ${ALL_GTESTS} PARENT_SCOPE)
endfunction()


# Gets all type values from all "typedef testing::Types<type, type, ...> varname" statements.
# For each varname, a variable named "varname_VAR" is set in parent_scope which contains all
# the types specified in the template parameters.
function(get_gtest_typedef_types GTEST_SOURCE_FILE)
  file(STRINGS ${GTEST_SOURCE_FILE} FILE_AS_STRING NEWLINE_CONSUME)
  string(REGEX MATCHALL testing::Types[.\n]*[^;]* TYPEDEFS ${FILE_AS_STRING})
  if(NOT TYPEDEFS)
    return()
  endif()
  foreach(TYPEDEF ${TYPEDEFS})
    string(REGEX REPLACE testing::Types<+ "" TYPEDEF ${TYPEDEF})
    string(REGEX REPLACE \n "" TYPEDEF ${TYPEDEF})
    string(REGEX MATCH >.* TYPEDEF_NAME ${TYPEDEF})
    string(REGEX REPLACE ${TYPEDEF_NAME} "" TYPEDEF ${TYPEDEF})
    string(REGEX REPLACE ["\ >"] "" TYPEDEF_NAME ${TYPEDEF_NAME})
    string(REGEX REPLACE ,["\ "]* ";" TYPEDEF ${TYPEDEF})
    set(${TYPEDEF_NAME}_VAR ${TYPEDEF} PARENT_SCOPE)
  endforeach()
endfunction()


# Gets instances of typed tests per test fixture.  For a fixture named test_fixture, a variable named
# "test_fixture_TYPES" is set in parent scope which contains a list of the fixture's names, but with
# the test case name portion replaced with "@@@@@" in preparation for adding the actual test case names
# for the fixture.  The names will be of the form "test_fixture/0.@@@@@", "test_fixture/1.@@@@@", ...
# "test_fixture/x.@@@@@" with "x" equal to the number of different types - 1 (as count starts at 0).
function(get_gtest_fixtures_types GTEST_SOURCE_FILE)
  file(STRINGS ${GTEST_SOURCE_FILE} FILE_AS_STRING NEWLINE_CONSUME)
  string(REGEX MATCHALL TYPED_TEST_CASE[.\n]*[^;]* TEST_TYPES ${FILE_AS_STRING})
  if(NOT TEST_TYPES)
    return()
  endif()
  foreach(TEST_TYPE ${TEST_TYPES})
    if(NOT "${TEST_TYPE}" MATCHES "^TYPED_TEST_CASE_P")
      string(REGEX REPLACE TYPED_TEST_CASE["\("]+ "" TEST_TYPE ${TEST_TYPE})
      string(REGEX REPLACE [\n\ ] "" TEST_TYPE ${TEST_TYPE})
      string(REGEX MATCH [^,]+ GTEST_FIXTURE_NAME ${TEST_TYPE})
      string(REGEX REPLACE ${GTEST_FIXTURE_NAME}, "" TEST_TYPE ${TEST_TYPE})
      string(REGEX REPLACE ["\)"] "" TYPEDEF_NAME ${TEST_TYPE})
      set(PARAMETER_COUNT 0)
      foreach(TYPE ${${TYPEDEF_NAME}_VAR})
        set(${GTEST_FIXTURE_NAME}_TYPES ${${GTEST_FIXTURE_NAME}_TYPES} "${GTEST_FIXTURE_NAME}/${PARAMETER_COUNT}.@@@@@")
        math(EXPR PARAMETER_COUNT ${PARAMETER_COUNT}+1)
      endforeach()
      set(${GTEST_FIXTURE_NAME}_TYPES ${${GTEST_FIXTURE_NAME}_TYPES} PARENT_SCOPE)
    endif()
  endforeach()
endfunction()


# Gets instances of value-parameterised tests per test fixture.  For a fixture named test_fixture,
# a variable named "test_fixture_VALUE_PARAMETERS" is set in parent scope which contains a list of
# the fixture's names, but with the test case name portion replaced with "@@@@@" in preparation for
# adding the actual test case names for the fixture.  The names will be of the form
# "instantiation_name/test_fixture.@@@@@/0", "instantiation_name/test_fixture.@@@@@/1",  ...
# "instantiation_name/test_fixture.@@@@@/x", with "x" equal to the number of different parameterised
# values - 1 (as count starts at 0).
function(get_gtest_fixtures_value_parameters GTEST_SOURCE_FILE)
  file(STRINGS ${GTEST_SOURCE_FILE} FILE_AS_STRING NEWLINE_CONSUME)
  string(REGEX MATCHALL INSTANTIATE_TEST_CASE_P[.\n]*[^;]* INSTANTIATIONS ${FILE_AS_STRING})
  if(NOT INSTANTIATIONS)
    return()
  endif()
  foreach(INSTANTIATION ${INSTANTIATIONS})
    string(REGEX REPLACE INSTANTIATE_TEST_CASE_P["\("]+ "" INSTANTIATION ${INSTANTIATION})
    string(REGEX REPLACE "//[^\n]*" "" INSTANTIATION ${INSTANTIATION})
    string(REGEX REPLACE [\n\ ] "" INSTANTIATION ${INSTANTIATION})
    string(REGEX MATCH [^,]+ PARTIAL_TEST_NAME ${INSTANTIATION})
    string(REGEX REPLACE ^${PARTIAL_TEST_NAME}, "" INSTANTIATION ${INSTANTIATION})
    string(REGEX MATCH [^,]+ GTEST_FIXTURE_NAME ${INSTANTIATION})
    set(PARTIAL_TEST_NAME ${PARTIAL_TEST_NAME}/${GTEST_FIXTURE_NAME}.@@@@@)
    string(REGEX REPLACE ${GTEST_FIXTURE_NAME}, "" INSTANTIATION ${INSTANTIATION})
    string(REGEX MATCH Range RANGE_TYPE ${INSTANTIATION})
    string(REGEX MATCH Values VALUES_TYPE ${INSTANTIATION})
    string(REGEX MATCH Bool BOOL_TYPE ${INSTANTIATION})
    set(PARAMETER_COUNT 0)
    if(RANGE_TYPE)
      string(REGEX MATCHALL [0-9\\.]+ VALUES ${INSTANTIATION})
      list(GET VALUES 0 CURRENT)
      list(GET VALUES 1 STOP)
      list(LENGTH VALUES LIST_LENGTH)
      if(LIST_LENGTH EQUAL 2)
        set(STEP 1)
      else()
        list(GET VALUES 2 STEP)
      endif()
      while(CURRENT LESS STOP)
        set(${GTEST_FIXTURE_NAME}_VALUE_PARAMETERS ${${GTEST_FIXTURE_NAME}_VALUE_PARAMETERS} "${PARTIAL_TEST_NAME}/${PARAMETER_COUNT}")
        math(EXPR PARAMETER_COUNT ${PARAMETER_COUNT}+1)
        math(EXPR CURRENT ${CURRENT}+${STEP})
      endwhile()
    elseif(VALUES_TYPE)
      string(REGEX REPLACE "[^\(]*[\(](.*)[\)][\)]" "\\1" INSTANTIATION ${INSTANTIATION})
      string(REGEX REPLACE "[\(][^\)]*[\)]" "" INSTANTIATION ${INSTANTIATION})
      string(REGEX REPLACE "," ";" VALUES ${INSTANTIATION})
      foreach(VALUE ${VALUES})
        set(${GTEST_FIXTURE_NAME}_VALUE_PARAMETERS ${${GTEST_FIXTURE_NAME}_VALUE_PARAMETERS} "${PARTIAL_TEST_NAME}/${PARAMETER_COUNT}")
        math(EXPR PARAMETER_COUNT ${PARAMETER_COUNT}+1)
      endforeach()
    elseif(BOOL_TYPE)
      set(${GTEST_FIXTURE_NAME}_VALUE_PARAMETERS ${${GTEST_FIXTURE_NAME}_VALUE_PARAMETERS} "${PARTIAL_TEST_NAME}/0;${PARTIAL_TEST_NAME}/1")
    endif()
    set(${GTEST_FIXTURE_NAME}_VALUE_PARAMETERS ${${GTEST_FIXTURE_NAME}_VALUE_PARAMETERS} PARENT_SCOPE)
  endforeach()
endfunction()


# Gets instances of type-parameterised tests per test fixture.  For a fixture named test_fixture,
# a variable named "test_fixture_TYPE_PARAMETERS" is set in parent scope which contains a list of
# the fixture's names, but with the test case name portion replaced with "@@@@@" in preparation for
# adding the actual test case names for the fixture.  The names will be of the form
# "instantiation_name/test_fixture/0.@@@@@", "instantiation_name/test_fixture/1.@@@@@",  ...
# "instantiation_name/test_fixture/x.@@@@@", with "x" equal to the number of different parameterised
# types - 1 (as count starts at 0).
function(get_gtest_fixtures_type_parameters GTEST_SOURCE_FILE)
  file(STRINGS ${GTEST_SOURCE_FILE} FILE_AS_STRING NEWLINE_CONSUME)
  string(REGEX MATCHALL INSTANTIATE_TYPED_TEST_CASE_P[.\n]*[^;]* INSTANTIATIONS ${FILE_AS_STRING})
  if(NOT INSTANTIATIONS)
    return()
  endif()
  foreach(INSTANTIATION ${INSTANTIATIONS})
    string(REGEX REPLACE INSTANTIATE_TYPED_TEST_CASE_P["\("]+ "" INSTANTIATION ${INSTANTIATION})
    string(REGEX REPLACE [\n\ ] "" INSTANTIATION ${INSTANTIATION})
    string(REGEX MATCH [^,]+ PARTIAL_TEST_NAME ${INSTANTIATION})
    string(REGEX REPLACE ${PARTIAL_TEST_NAME}, "" INSTANTIATION ${INSTANTIATION})
    string(REGEX MATCH [^,]+ GTEST_FIXTURE_NAME ${INSTANTIATION})
    set(PARTIAL_TEST_NAME ${PARTIAL_TEST_NAME}/${GTEST_FIXTURE_NAME})
    string(REGEX REPLACE ${GTEST_FIXTURE_NAME}, "" INSTANTIATION ${INSTANTIATION})
    string(REGEX REPLACE ["\)"] "" TYPEDEF_NAME ${INSTANTIATION})
    # The 3rd parameter of INSTANTIATE_TYPED_TEST_CASE_P can be either a single type to be run, or a typedef
    # of a testing::Types with several types to be run.  If we can't find a parsed typedef to match we'll
    # assume it's a single type.
    if(DEFINED ${TYPEDEF_NAME}_VAR)
      set(PARAMETER_COUNT 0)
      foreach(TYPE ${${TYPEDEF_NAME}_VAR})
        set(${GTEST_FIXTURE_NAME}_TYPE_PARAMETERS ${${GTEST_FIXTURE_NAME}_TYPE_PARAMETERS} ${PARTIAL_TEST_NAME}/${PARAMETER_COUNT}.@@@@@)
        math(EXPR PARAMETER_COUNT ${PARAMETER_COUNT}+1)
      endforeach()
    else()
      set(${GTEST_FIXTURE_NAME}_TYPE_PARAMETERS ${${GTEST_FIXTURE_NAME}_TYPE_PARAMETERS} ${PARTIAL_TEST_NAME}/0.@@@@@)
    endif()
    set(${GTEST_FIXTURE_NAME}_TYPE_PARAMETERS ${${GTEST_FIXTURE_NAME}_TYPE_PARAMETERS} PARENT_SCOPE)
  endforeach()
endfunction()


# For type-parameterised tests, this reads the contents of macros REGISTER_TYPED_TEST_CASE_P(...).
# These contain the test fixture and all the test cases for that fixture.  This consequently
# adds tests by replacing the "@@@@@"s in each value in "test_fixture_TYPE_PARAMETERS" (which is
# generated by the function get_gtest_fixtures_type_parameters above) multiple times - once per
# test name.
function(add_gtest_registered_typed_tests GTEST_SOURCE_FILE TEST_TARGET)
  set(TEST_EXECUTABLE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${TEST_TARGET}${TEST_POSTFIX})
  file(STRINGS ${GTEST_SOURCE_FILE} FILE_AS_STRING NEWLINE_CONSUME)
  # Remove single-line comments and block comments
  string(REGEX REPLACE "//[^\n]*\n" "" FILE_AS_STRING "${FILE_AS_STRING}")
  ms_remove_block_comments(FILE_AS_STRING)

  string(REGEX MATCHALL "REGISTER_TYPED_TEST_CASE_P[.\n]*[^;]*" REGISTEREDS ${FILE_AS_STRING})
  if(NOT REGISTEREDS)
    return()
  endif()
  foreach(REGISTERED ${REGISTEREDS})
    string(REGEX REPLACE REGISTER_TYPED_TEST_CASE_P["\("]+ "" REGISTERED ${REGISTERED})
    string(REGEX REPLACE [\n\ ] "" REGISTERED ${REGISTERED})
    string(REGEX MATCH [^,]+ GTEST_FIXTURE_NAME ${REGISTERED})
    string(REGEX REPLACE ${GTEST_FIXTURE_NAME}, "" REGISTERED ${REGISTERED})
    string(REGEX REPLACE ["\)"] "" REGISTERED ${REGISTERED})
    string(REGEX REPLACE [,] ";" GTEST_NAMES ${REGISTERED})
    foreach(GTEST_NAME ${GTEST_NAMES})
      foreach(TYPE_PARAMETER ${${GTEST_FIXTURE_NAME}_TYPE_PARAMETERS})
        string(REGEX REPLACE "@@@@@" ${GTEST_NAME} FULL_GTEST_NAME ${TYPE_PARAMETER})
        add_maidsafe_test(${GTEST_FIXTURE_NAME} ${GTEST_NAME} ${FULL_GTEST_NAME} ${TEST_EXECUTABLE})
      endforeach()
    endforeach()
  endforeach()
  set(ALL_GTESTS ${ALL_GTESTS} PARENT_SCOPE)
endfunction()


# This reads the contents of macros TEST(...), TEST_F(...), TEST_P(...), and TYPED_TEST(...)
# (i.e. all tests other than type-parameterised tests).  These contain the test fixture and
# test name.  This consequently adds value-parameterised tests by replacing the "@@@@@"s in
# each value in "test_fixture_VALUE_PARAMETERS" (which is generated by the function
# get_gtest_fixtures_value_parameters above) multiple times - once per test name.  It also
# adds typed tests by replacing the "@@@@@"s in each value in "test_fixture_TYPES" (which is
# generated by the function get_gtest_fixtures_types above) multiple times - once per test
# name.  It also adds basic tests from TEST(...) and TEST_F(...).
function(add_gtest_non_type_parameterised GTEST_SOURCE_FILE TEST_TARGET)
  set(TEST_EXECUTABLE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${TEST_TARGET}${TEST_POSTFIX})
  file(STRINGS ${GTEST_SOURCE_FILE} GTEST_NAMES REGEX "^(TYPED_)?TEST(_[FP])?\\(")
  foreach(GTEST_NAME ${GTEST_NAMES})
    string(REGEX MATCH "TEST_MS_NET" TEST_IS_MS_NETWORK_TYPE ${GTEST_NAME})
    string(REGEX REPLACE ["\) \(,"] ";" GTEST_NAME ${GTEST_NAME})
    list(GET GTEST_NAME 0 GTEST_TEST_TYPE)
    list(GET GTEST_NAME 1 GTEST_FIXTURE_NAME)
    if(TEST_IS_MS_NETWORK_TYPE)
      list(GET GTEST_NAME 3 GTEST_NAME_PART1)
      list(GET GTEST_NAME 5 GTEST_NAME_PART2)
      list(GET GTEST_NAME 7 GTEST_NAME_PART3)
      set(GTEST_NAME "${GTEST_NAME_PART1}_${GTEST_NAME_PART2}_${GTEST_NAME_PART3}")
    else()
      list(GET GTEST_NAME 3 GTEST_NAME)
    endif()
    if(${GTEST_TEST_TYPE} MATCHES ^TEST_P$)  # Value-parameterised tests
      foreach(VALUE_PARAMETER ${${GTEST_FIXTURE_NAME}_VALUE_PARAMETERS})
        string(REGEX REPLACE "@@@@@" ${GTEST_NAME} FULL_GTEST_NAME ${VALUE_PARAMETER})
        add_maidsafe_test(${GTEST_FIXTURE_NAME} ${GTEST_NAME} ${FULL_GTEST_NAME} ${TEST_EXECUTABLE})
      endforeach()
    elseif(${GTEST_TEST_TYPE} MATCHES ^TYPED_TEST$)  # Typed tests
      foreach(TYPE ${${GTEST_FIXTURE_NAME}_TYPES})
        string(REGEX REPLACE "@@@@@" ${GTEST_NAME} FULL_GTEST_NAME ${TYPE})
        add_maidsafe_test(${GTEST_FIXTURE_NAME} ${GTEST_NAME} ${FULL_GTEST_NAME} ${TEST_EXECUTABLE})
      endforeach()
    elseif(NOT ${GTEST_TEST_TYPE} MATCHES ^TYPED_TEST_P$)  # Others, excluding type-parameterised tests
      add_maidsafe_test(${GTEST_FIXTURE_NAME} ${GTEST_NAME} ${GTEST_FIXTURE_NAME}.${GTEST_NAME} ${TEST_EXECUTABLE})
    endif()
  endforeach()
  set(ALL_GTESTS ${ALL_GTESTS} PARENT_SCOPE)
endfunction()


# This adds the test (after checking it is of appropriate type and not explicitly excluded)
# and sets label and timeout properties.
function(add_maidsafe_test GTEST_FIXTURE_NAME GTEST_NAME FULL_GTEST_NAME TEST_EXECUTABLE)
  if((${GTEST_NAME} MATCHES ${MAIDSAFE_TEST_TYPE}.+) OR (${MAIDSAFE_TEST_TYPE} MATCHES "ALL"))
    list(FIND EXCLUDED_TESTS ${FULL_GTEST_NAME} THIS_GTEST_EXCLUDED)
    if(THIS_GTEST_EXCLUDED EQUAL -1)
      if("${GTEST_NAME}" MATCHES "^DISABLED_")
        add_test(${FULL_GTEST_NAME} "__disabled__")
      else()
        string(REPLACE "/" "" TEST_EXECUTABLE ${TEST_EXECUTABLE})
        if(RUNNING_AS_CTEST_SCRIPT)
          set(CATCH_EXCEPTIONS "1")
        else()
          set(CATCH_EXCEPTIONS "0")
        endif()
        add_test(NAME ${FULL_GTEST_NAME}
                 COMMAND ${TEST_EXECUTABLE} --gtest_filter=${FULL_GTEST_NAME} --gtest_catch_exceptions=${CATCH_EXCEPTIONS})
      endif()
      if("${GTEST_NAME}" MATCHES "^FUNC_" OR "${GTEST_NAME}" MATCHES "^DISABLED_FUNC_")
        set_property(TEST ${FULL_GTEST_NAME} PROPERTY LABELS ${CamelCaseProjectName} Functional)
        ms_update_test_timeout(FUNCTIONAL_TEST_TIMEOUT)
        set_property(TEST ${FULL_GTEST_NAME} PROPERTY TIMEOUT ${FUNCTIONAL_TEST_TIMEOUT})
      elseif("${GTEST_NAME}" MATCHES "^BEH_" OR "${GTEST_NAME}" MATCHES "^DISABLED_BEH_")
        set_property(TEST ${FULL_GTEST_NAME} PROPERTY LABELS ${CamelCaseProjectName} Behavioural)
        ms_update_test_timeout(BEHAVIOURAL_TEST_TIMEOUT)
        set_property(TEST ${FULL_GTEST_NAME} PROPERTY TIMEOUT ${BEHAVIOURAL_TEST_TIMEOUT})
      elseif(NOT "${GTEST_NAME}" MATCHES "^//")
        message("")
        message("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        message("")
        message(AUTHOR_WARNING "${GTEST_NAME} should be named \"BEH_...\" or \"FUNC_...\" (with an optional \"DISABLED_\" prepended).")
        message("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
      endif()
      set(ALL_GTESTS ${ALL_GTESTS} ${FULL_GTEST_NAME} PARENT_SCOPE)
    endif()
  endif()
endfunction()
