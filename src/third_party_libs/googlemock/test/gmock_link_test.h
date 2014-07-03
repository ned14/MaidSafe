// Copyright 2009, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Author: vladl@google.com (Vlad Losev)

// Google Mock - a framework for writing C++ mock classes.
//
// This file tests that:
// a. A header file defining a mock class can be included in multiple
//    translation units without causing a link error.
// b. Actions and matchers can be instantiated with identical template
//    arguments in different translation units without causing link
//    errors.
//    The following constructs are currently tested:
//    Actions:
//      Return()
//      Return(value)
//      ReturnNull
//      ReturnRef
//      Assign
//      SetArgPointee
//      SetArrayArgument
//      SetErrnoAndReturn
//      Invoke(function)
//      Invoke(object, method)
//      InvokeWithoutArgs(function)
//      InvokeWithoutArgs(object, method)
//      InvokeArgument
//      WithArg
//      WithArgs
//      WithoutArgs
//      DoAll
//      DoDefault
//      IgnoreResult
//      Throw
//      ACTION()-generated
//      ACTION_P()-generated
//      ACTION_P2()-generated
//    Matchers:
//      _
//      A
//      An
//      Eq
//      Gt, Lt, Ge, Le, Ne
//      NotNull
//      Ref
//      TypedEq
//      DoubleEq
//      FloatEq
//      NanSensitiveDoubleEq
//      NanSensitiveFloatEq
//      ContainsRegex
//      MatchesRegex
//      EndsWith
//      HasSubstr
//      StartsWith
//      StrCaseEq
//      StrCaseNe
//      StrEq
//      StrNe
//      ElementsAre
//      ElementsAreArray
//      ContainerEq
//      Field
//      Property
//      ResultOf(function)
//      Pointee
//      Truly(predicate)
//      AllOf
//      AnyOf
//      Not
//      MatcherCast<T>
//
//  Please note: this test does not verify the functioning of these
//  constructs, only that the programs using them will link successfully.
//
// Implementation note:
// This test requires identical definitions of Interface and Mock to be
// included in different translation units.  We achieve this by writing
// them in this header and #including it in gmock_link_test.cc and
// gmock_link2_test.cc.  Because the symbols generated by the compiler for
// those constructs must be identical in both translation units,
// definitions of Interface and Mock tests MUST be kept in the SAME
// NON-ANONYMOUS namespace in this file.  The test fixture class LinkTest
// is defined as LinkTest1 in gmock_link_test.cc and as LinkTest2 in
// gmock_link2_test.cc to avoid producing linker errors.

#ifndef GMOCK_TEST_GMOCK_LINK_TEST_H_
#define GMOCK_TEST_GMOCK_LINK_TEST_H_

#include "gmock/gmock.h"

#if !defined GTEST_OS_WINDOWS_MOBILE || !GTEST_OS_WINDOWS_MOBILE
# include <errno.h>
#endif

#include "gmock/internal/gmock-port.h"
#include "gtest/gtest.h"
#include <iostream>
#include <vector>

using testing::_;
using testing::A;
using testing::AllOf;
using testing::AnyOf;
using testing::Assign;
using testing::ContainerEq;
using testing::DoAll;
using testing::DoDefault;
using testing::DoubleEq;
using testing::ElementsAre;
using testing::ElementsAreArray;
using testing::EndsWith;
using testing::Eq;
using testing::Field;
using testing::FloatEq;
using testing::Ge;
using testing::Gt;
using testing::HasSubstr;
using testing::IgnoreResult;
using testing::Invoke;
using testing::InvokeArgument;
using testing::InvokeWithoutArgs;
using testing::IsNull;
using testing::Le;
using testing::Lt;
using testing::Matcher;
using testing::MatcherCast;
using testing::NanSensitiveDoubleEq;
using testing::NanSensitiveFloatEq;
using testing::Ne;
using testing::Not;
using testing::NotNull;
using testing::Pointee;
using testing::Property;
using testing::Ref;
using testing::ResultOf;
using testing::Return;
using testing::ReturnNull;
using testing::ReturnRef;
using testing::SetArgPointee;
using testing::SetArrayArgument;
using testing::StartsWith;
using testing::StrCaseEq;
using testing::StrCaseNe;
using testing::StrEq;
using testing::StrNe;
using testing::Truly;
using testing::TypedEq;
using testing::WithArg;
using testing::WithArgs;
using testing::WithoutArgs;

#if !defined GTEST_OS_WINDOWS_MOBILE || !GTEST_OS_WINDOWS_MOBILE
using testing::SetErrnoAndReturn;
#endif

#if GTEST_HAS_EXCEPTIONS
using testing::Throw;
#endif

using testing::ContainsRegex;
using testing::MatchesRegex;

class Interface {
 public:
  virtual ~Interface() {}
  virtual void VoidFromString(char* str) = 0;
  virtual char* StringFromString(char* str) = 0;
  virtual int IntFromString(char* str) = 0;
  virtual int& IntRefFromString(char* str) = 0;
  virtual void VoidFromFunc(void(*func)(char* str)) = 0;
  virtual void VoidFromIntRef(int& n) = 0;  // NOLINT
  virtual void VoidFromFloat(float n) = 0;
  virtual void VoidFromDouble(double n) = 0;
  virtual void VoidFromVector(const std::vector<int>& v) = 0;
};

class Mock: public Interface {
 public:
  Mock() {}

  MOCK_METHOD1(VoidFromString, void(char* str));
  MOCK_METHOD1(StringFromString, char*(char* str));
  MOCK_METHOD1(IntFromString, int(char* str));
  MOCK_METHOD1(IntRefFromString, int&(char* str));
  MOCK_METHOD1(VoidFromFunc, void(void(*func)(char* str)));
  MOCK_METHOD1(VoidFromIntRef, void(int& n));  // NOLINT
  MOCK_METHOD1(VoidFromFloat, void(float n));
  MOCK_METHOD1(VoidFromDouble, void(double n));
  MOCK_METHOD1(VoidFromVector, void(const std::vector<int>& v));

 private:
  GTEST_DISALLOW_COPY_AND_ASSIGN_(Mock);
};

class InvokeHelper {
 public:
  static void StaticVoidFromVoid() {}
  void VoidFromVoid() {}
  static void StaticVoidFromString(char* /* str */) {}
  void VoidFromString(char* /* str */) {}
  static int StaticIntFromString(char* /* str */) { return 1; }
  static bool StaticBoolFromString(const char* /* str */) { return true; }
};

class FieldHelper {
 public:
  explicit FieldHelper(int a_field) : field_(a_field) {}
  int field() const { return field_; }
  int field_;  // NOLINT -- need external access to field_ to test
               //           the Field matcher.
};

// Tests the linkage of the ReturnVoid action.
TEST(LinkTest, TestReturnVoid) {
  Mock mock;

  EXPECT_CALL(mock, VoidFromString(_)).WillOnce(Return());
  mock.VoidFromString(NULL);
}

// Tests the linkage of the Return action.
TEST(LinkTest, TestReturn) {
  Mock mock;
  char ch = 'x';

  EXPECT_CALL(mock, StringFromString(_)).WillOnce(Return(&ch));
  mock.StringFromString(NULL);
}

// Tests the linkage of the ReturnNull action.
TEST(LinkTest, TestReturnNull) {
  Mock mock;

  EXPECT_CALL(mock, VoidFromString(_)).WillOnce(Return());
  mock.VoidFromString(NULL);
}

// Tests the linkage of the ReturnRef action.
TEST(LinkTest, TestReturnRef) {
  Mock mock;
  int n = 42;

  EXPECT_CALL(mock, IntRefFromString(_)).WillOnce(ReturnRef(n));
  mock.IntRefFromString(NULL);
}

// Tests the linkage of the Assign action.
TEST(LinkTest, TestAssign) {
  Mock mock;
  char ch = 'x';

  EXPECT_CALL(mock, VoidFromString(_)).WillOnce(Assign(&ch, 'y'));
  mock.VoidFromString(NULL);
}

// Tests the linkage of the SetArgPointee action.
TEST(LinkTest, TestSetArgPointee) {
  Mock mock;
  char ch = 'x';

  EXPECT_CALL(mock, VoidFromString(_)).WillOnce(SetArgPointee<0>('y'));
  mock.VoidFromString(&ch);
}

// Tests the linkage of the SetArrayArgument action.
TEST(LinkTest, TestSetArrayArgument) {
  Mock mock;
  char ch = 'x';
  char ch2 = 'y';

  EXPECT_CALL(mock, VoidFromString(_)).WillOnce(SetArrayArgument<0>(&ch2,
                                                                    &ch2 + 1));
  mock.VoidFromString(&ch);
}

#if !defined GTEST_OS_WINDOWS_MOBILE || !GTEST_OS_WINDOWS_MOBILE

// Tests the linkage of the SetErrnoAndReturn action.
TEST(LinkTest, TestSetErrnoAndReturn) {
  Mock mock;

  int saved_errno = errno;
  EXPECT_CALL(mock, IntFromString(_)).WillOnce(SetErrnoAndReturn(1, -1));
  mock.IntFromString(NULL);
  errno = saved_errno;
}

#endif  // !GTEST_OS_WINDOWS_MOBILE

// Tests the linkage of the Invoke(function) and Invoke(object, method) actions.
TEST(LinkTest, TestInvoke) {
  Mock mock;
  InvokeHelper test_invoke_helper;

  EXPECT_CALL(mock, VoidFromString(_))
      .WillOnce(Invoke(&InvokeHelper::StaticVoidFromString))
      .WillOnce(Invoke(&test_invoke_helper, &InvokeHelper::VoidFromString));
  mock.VoidFromString(NULL);
  mock.VoidFromString(NULL);
}

// Tests the linkage of the InvokeWithoutArgs action.
TEST(LinkTest, TestInvokeWithoutArgs) {
  Mock mock;
  InvokeHelper test_invoke_helper;

  EXPECT_CALL(mock, VoidFromString(_))
      .WillOnce(InvokeWithoutArgs(&InvokeHelper::StaticVoidFromVoid))
      .WillOnce(InvokeWithoutArgs(&test_invoke_helper,
                                  &InvokeHelper::VoidFromVoid));
  mock.VoidFromString(NULL);
  mock.VoidFromString(NULL);
}

// Tests the linkage of the InvokeArgument action.
TEST(LinkTest, TestInvokeArgument) {
  Mock mock;
  char ch = 'x';

  EXPECT_CALL(mock, VoidFromFunc(_)).WillOnce(InvokeArgument<0>(&ch));
  mock.VoidFromFunc(InvokeHelper::StaticVoidFromString);
}

// Tests the linkage of the WithArg action.
TEST(LinkTest, TestWithArg) {
  Mock mock;

  EXPECT_CALL(mock, VoidFromString(_))
      .WillOnce(WithArg<0>(Invoke(&InvokeHelper::StaticVoidFromString)));
  mock.VoidFromString(NULL);
}

// Tests the linkage of the WithArgs action.
TEST(LinkTest, TestWithArgs) {
  Mock mock;

  EXPECT_CALL(mock, VoidFromString(_))
      .WillOnce(WithArgs<0>(Invoke(&InvokeHelper::StaticVoidFromString)));
  mock.VoidFromString(NULL);
}

// Tests the linkage of the WithoutArgs action.
TEST(LinkTest, TestWithoutArgs) {
  Mock mock;

  EXPECT_CALL(mock, VoidFromString(_)).WillOnce(WithoutArgs(Return()));
  mock.VoidFromString(NULL);
}

// Tests the linkage of the DoAll action.
TEST(LinkTest, TestDoAll) {
  Mock mock;
  char ch = 'x';

  EXPECT_CALL(mock, VoidFromString(_))
      .WillOnce(DoAll(SetArgPointee<0>('y'), Return()));
  mock.VoidFromString(&ch);
}

// Tests the linkage of the DoDefault action.
TEST(LinkTest, TestDoDefault) {
  Mock mock;
  char ch = 'x';

  ON_CALL(mock, VoidFromString(_)).WillByDefault(Return());
  EXPECT_CALL(mock, VoidFromString(_)).WillOnce(DoDefault());
  mock.VoidFromString(&ch);
}

// Tests the linkage of the IgnoreResult action.
TEST(LinkTest, TestIgnoreResult) {
  Mock mock;

  EXPECT_CALL(mock, VoidFromString(_)).WillOnce(IgnoreResult(Return(42)));
  mock.VoidFromString(NULL);
}

#if GTEST_HAS_EXCEPTIONS
// Tests the linkage of the Throw action.
TEST(LinkTest, TestThrow) {
  Mock mock;

  EXPECT_CALL(mock, VoidFromString(_)).WillOnce(Throw(42));
  EXPECT_THROW(mock.VoidFromString(NULL), int);
}
#endif  // GTEST_HAS_EXCEPTIONS

// The ACTION*() macros trigger warning C4100 (unreferenced formal
// parameter) in MSVC with -W4.  Unfortunately they cannot be fixed in
// the macro definition, as the warnings are generated when the macro
// is expanded and macro expansion cannot contain #pragma.  Therefore
// we suppress them here.
#ifdef _MSC_VER
# pragma warning(push)
# pragma warning(disable:4100)
#endif

// Tests the linkage of actions created using ACTION macro.
namespace {
ACTION(Return1) { return 1; }
}

TEST(LinkTest, TestActionMacro) {
  Mock mock;

  EXPECT_CALL(mock, IntFromString(_)).WillOnce(Return1());
  mock.IntFromString(NULL);
}

// Tests the linkage of actions created using ACTION_P macro.
namespace {
ACTION_P(ReturnArgument, ret_value) { return ret_value; }
}

TEST(LinkTest, TestActionPMacro) {
  Mock mock;

  EXPECT_CALL(mock, IntFromString(_)).WillOnce(ReturnArgument(42));
  mock.IntFromString(NULL);
}

// Tests the linkage of actions created using ACTION_P2 macro.
namespace {
ACTION_P2(ReturnEqualsEitherOf, first, second) {
  return arg0 == first || arg0 == second;
}
}

#ifdef _MSC_VER
# pragma warning(pop)
#endif

TEST(LinkTest, TestActionP2Macro) {
  Mock mock;
  char ch = 'x';

  EXPECT_CALL(mock, IntFromString(_))
      .WillOnce(ReturnEqualsEitherOf("one", "two"));
  mock.IntFromString(&ch);
}

// Tests the linkage of the "_" matcher.
TEST(LinkTest, TestMatcherAnything) {
  Mock mock;

  ON_CALL(mock, VoidFromString(_)).WillByDefault(Return());
}

// Tests the linkage of the A matcher.
TEST(LinkTest, TestMatcherA) {
  Mock mock;

  ON_CALL(mock, VoidFromString(A<char*>())).WillByDefault(Return());
}

// Tests the linkage of the Eq and the "bare value" matcher.
TEST(LinkTest, TestMatchersEq) {
  Mock mock;
  const char* p = "x";

  ON_CALL(mock, VoidFromString(Eq(p))).WillByDefault(Return());
  ON_CALL(mock, VoidFromString(const_cast<char*>("y")))
      .WillByDefault(Return());
}

// Tests the linkage of the Lt, Gt, Le, Ge, and Ne matchers.
TEST(LinkTest, TestMatchersRelations) {
  Mock mock;

  ON_CALL(mock, VoidFromFloat(Lt(1.0f))).WillByDefault(Return());
  ON_CALL(mock, VoidFromFloat(Gt(1.0f))).WillByDefault(Return());
  ON_CALL(mock, VoidFromFloat(Le(1.0f))).WillByDefault(Return());
  ON_CALL(mock, VoidFromFloat(Ge(1.0f))).WillByDefault(Return());
  ON_CALL(mock, VoidFromFloat(Ne(1.0f))).WillByDefault(Return());
}

// Tests the linkage of the NotNull matcher.
TEST(LinkTest, TestMatcherNotNull) {
  Mock mock;

  ON_CALL(mock, VoidFromString(NotNull())).WillByDefault(Return());
}

// Tests the linkage of the IsNull matcher.
TEST(LinkTest, TestMatcherIsNull) {
  Mock mock;

  ON_CALL(mock, VoidFromString(IsNull())).WillByDefault(Return());
}

// Tests the linkage of the Ref matcher.
TEST(LinkTest, TestMatcherRef) {
  Mock mock;
  int a = 0;

  ON_CALL(mock, VoidFromIntRef(Ref(a))).WillByDefault(Return());
}

// Tests the linkage of the TypedEq matcher.
TEST(LinkTest, TestMatcherTypedEq) {
  Mock mock;
  long a = 0;

  ON_CALL(mock, VoidFromIntRef(TypedEq<int&>(a))).WillByDefault(Return());
}

// Tests the linkage of the FloatEq, DoubleEq, NanSensitiveFloatEq and
// NanSensitiveDoubleEq matchers.
TEST(LinkTest, TestMatchersFloatingPoint) {
  Mock mock;
  float a = 0;

  ON_CALL(mock, VoidFromFloat(FloatEq(a))).WillByDefault(Return());
  ON_CALL(mock, VoidFromDouble(DoubleEq(a))).WillByDefault(Return());
  ON_CALL(mock, VoidFromFloat(NanSensitiveFloatEq(a))).WillByDefault(Return());
  ON_CALL(mock, VoidFromDouble(NanSensitiveDoubleEq(a)))
      .WillByDefault(Return());
}

// Tests the linkage of the ContainsRegex matcher.
TEST(LinkTest, TestMatcherContainsRegex) {
  Mock mock;

  ON_CALL(mock, VoidFromString(ContainsRegex(".*"))).WillByDefault(Return());
}

// Tests the linkage of the MatchesRegex matcher.
TEST(LinkTest, TestMatcherMatchesRegex) {
  Mock mock;

  ON_CALL(mock, VoidFromString(MatchesRegex(".*"))).WillByDefault(Return());
}

// Tests the linkage of the StartsWith, EndsWith, and HasSubstr matchers.
TEST(LinkTest, TestMatchersSubstrings) {
  Mock mock;

  ON_CALL(mock, VoidFromString(StartsWith("a"))).WillByDefault(Return());
  ON_CALL(mock, VoidFromString(EndsWith("c"))).WillByDefault(Return());
  ON_CALL(mock, VoidFromString(HasSubstr("b"))).WillByDefault(Return());
}

// Tests the linkage of the StrEq, StrNe, StrCaseEq, and StrCaseNe matchers.
TEST(LinkTest, TestMatchersStringEquality) {
  Mock mock;
  ON_CALL(mock, VoidFromString(StrEq("a"))).WillByDefault(Return());
  ON_CALL(mock, VoidFromString(StrNe("a"))).WillByDefault(Return());
  ON_CALL(mock, VoidFromString(StrCaseEq("a"))).WillByDefault(Return());
  ON_CALL(mock, VoidFromString(StrCaseNe("a"))).WillByDefault(Return());
}

// Tests the linkage of the ElementsAre matcher.
TEST(LinkTest, TestMatcherElementsAre) {
  Mock mock;

  ON_CALL(mock, VoidFromVector(ElementsAre('a', _))).WillByDefault(Return());
}

// Tests the linkage of the ElementsAreArray matcher.
TEST(LinkTest, TestMatcherElementsAreArray) {
  Mock mock;
  char arr[] = { 'a', 'b' };

  ON_CALL(mock, VoidFromVector(ElementsAreArray(arr))).WillByDefault(Return());
}

// Tests the linkage of the ContainerEq matcher.
TEST(LinkTest, TestMatcherContainerEq) {
  Mock mock;
  std::vector<int> v;

  ON_CALL(mock, VoidFromVector(ContainerEq(v))).WillByDefault(Return());
}

// Tests the linkage of the Field matcher.
TEST(LinkTest, TestMatcherField) {
  FieldHelper helper(0);

  Matcher<const FieldHelper&> m = Field(&FieldHelper::field_, Eq(0));
  EXPECT_TRUE(m.Matches(helper));

  Matcher<const FieldHelper*> m2 = Field(&FieldHelper::field_, Eq(0));
  EXPECT_TRUE(m2.Matches(&helper));
}

// Tests the linkage of the Property matcher.
TEST(LinkTest, TestMatcherProperty) {
  FieldHelper helper(0);

  Matcher<const FieldHelper&> m = Property(&FieldHelper::field, Eq(0));
  EXPECT_TRUE(m.Matches(helper));

  Matcher<const FieldHelper*> m2 = Property(&FieldHelper::field, Eq(0));
  EXPECT_TRUE(m2.Matches(&helper));
}

// Tests the linkage of the ResultOf matcher.
TEST(LinkTest, TestMatcherResultOf) {
  Matcher<char*> m = ResultOf(&InvokeHelper::StaticIntFromString, Eq(1));
  EXPECT_TRUE(m.Matches(NULL));
}

// Tests the linkage of the ResultOf matcher.
TEST(LinkTest, TestMatcherPointee) {
  int n = 1;

  Matcher<int*> m = Pointee(Eq(1));
  EXPECT_TRUE(m.Matches(&n));
}

// Tests the linkage of the Truly matcher.
TEST(LinkTest, TestMatcherTruly) {
  Matcher<const char*> m = Truly(&InvokeHelper::StaticBoolFromString);
  EXPECT_TRUE(m.Matches(NULL));
}

// Tests the linkage of the AllOf matcher.
TEST(LinkTest, TestMatcherAllOf) {
  Matcher<int> m = AllOf(_, Eq(1));
  EXPECT_TRUE(m.Matches(1));
}

// Tests the linkage of the AnyOf matcher.
TEST(LinkTest, TestMatcherAnyOf) {
  Matcher<int> m = AnyOf(_, Eq(1));
  EXPECT_TRUE(m.Matches(1));
}

// Tests the linkage of the Not matcher.
TEST(LinkTest, TestMatcherNot) {
  Matcher<int> m = Not(_);
  EXPECT_FALSE(m.Matches(1));
}

// Tests the linkage of the MatcherCast<T>() function.
TEST(LinkTest, TestMatcherCast) {
  Matcher<const char*> m = MatcherCast<const char*>(_);
  EXPECT_TRUE(m.Matches(NULL));
}

#endif  // GMOCK_TEST_GMOCK_LINK_TEST_H_
