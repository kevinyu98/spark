/**
   Licensed to the Apache Software Foundation (ASF) under one or more
   contributor license agreements.  See the NOTICE file distributed with
   this work for additional information regarding copyright ownership.
   The ASF licenses this file to You under the Apache License, Version 2.0
   (the "License"); you may not use this file except in compliance with
   the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   This file is an adaptation of Hive's org/apache/hadoop/hive/ql/IdentifiersParser.g grammar.
*/

parser grammar ExpressionParser2;

options
{
output=AST;
ASTLabelType=CommonTree;
backtrack=false;
k=3;
}

@members {
  @Override
  public Object recoverFromMismatchedSet(IntStream input,
      RecognitionException re, BitSet follow) throws RecognitionException {
    throw re;
  }
  @Override
  public void displayRecognitionError(String[] tokenNames,
      RecognitionException e) {
    gParent.displayRecognitionError(tokenNames, e);
  }
  protected boolean useSQL11ReservedKeywordsForIdentifier() {
    return gParent.useSQL11ReservedKeywordsForIdentifier();
  }
}

@rulecatch {
catch (RecognitionException e) {
  throw e;
}
}


// fun(par1, par2, par3)
function
@init { gParent.pushMsg("function specification", state); }
@after { gParent.popMsg(state); }
    :
    functionName
    LPAREN
      (
        (STAR) => (star=STAR)
       // | (to=KW_BOTH KW_FROM) (selectExpression)
        | (trimBoth=KW_BOTH sl=StringLiteral KW_FROM) (selectExpression)
        | (trimLead=KW_LEADING sl=StringLiteral KW_FROM) (selectExpression)
        | (trimTrail=KW_TRAILING sl=StringLiteral KW_FROM) (selectExpression)
        | (optDist=KW_DISTINCT)? (selectExpression (COMMA selectExpression)*)?

      )
    RPAREN (KW_OVER ws=window_specification)?
           -> {$star != null}? ^(TOK_FUNCTIONSTAR functionName $ws?)
           -> {$trimBoth != null}? ^(TOK_FUNCTIONTRBOTH functionName $sl selectExpression $ws?)
           -> {$trimLead != null}? ^(TOK_FUNCTIONTRLEAD functionName $sl selectExpression $ws?)
           -> {$trimTrail != null}? ^(TOK_FUNCTIONTRTRAIL functionName $sl selectExpression $ws?)
           -> {$optDist != null}? ^(TOK_FUNCTIONDI functionName (selectExpression+)? $ws?)
                            -> ^(TOK_FUNCTION functionName  (selectExpression+)? $ws?)
    ;



functionName
@init { gParent.pushMsg("function name", state); }
@after { gParent.popMsg(state); }
    : // Keyword IF is also a function name
    (KW_IF | KW_ARRAY | KW_MAP | KW_STRUCT | KW_UNIONTYPE) => (KW_IF | KW_ARRAY | KW_MAP | KW_STRUCT | KW_UNIONTYPE)
    |
    (functionIdentifier) => functionIdentifier
    |
    {!useSQL11ReservedKeywordsForIdentifier()}? sql11ReservedKeywordsUsedAsCastFunctionName -> Identifier[$sql11ReservedKeywordsUsedAsCastFunctionName.text]
    ;

