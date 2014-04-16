-- BUY INFO TYPE
CREATE OR REPLACE TYPE BUY_INFO_TYPE AS OBJECT (
  TRD_DATE   CHAR(8)       -- 거래일자
, FUND_CODE  CHAR(10)      -- 펀드코드
, BOND_CODE  CHAR(12)      -- 종목코드
, BUY_PRICE  NUMBER(22)    -- 매수단가
, BUY_QTY    NUMBER(22)    -- 매수수량
, BOND_IR    NUMBER(15,12) -- 표면이자율
, STL_DT_TP  CHAR(1)       -- 결제일구분(1.당일, 2.익일)
);
/

-- SELL INFO TYPE
CREATE OR REPLACE TYPE SELL_INFO_TYPE AS OBJECT (
  TRD_DATE   CHAR(8)    -- 거래일자(잔고 PK)
, FUND_CODE  CHAR(10)   -- 펀드코드(잔고 PK)
, BOND_CODE  CHAR(12)   -- 종목코드(잔고 PK)
, BUY_DATE   CHAR(8)    -- 매수일자(잔고 PK)
, BUY_PRICE  NUMBER(13) -- 매수단가(잔고 PK)
, BALAN_SEQ  NUMBER(13) -- 잔고일련번호(잔고 PK)
, SELL_PRICE NUMBER(22) -- 매도단가
, SELL_QTY   NUMBER(22) -- 매도수량
, STL_DT_TP  CHAR(1)    -- 결제일구분(1.당일, 2.익일)
);
/

-- CANCEL INFO TYPE
CREATE OR REPLACE TYPE CANCEL_INFO_TYPE AS OBJECT (
  TRD_DATE CHAR(8)    -- 거래일자(거래내역 PK)
, TRD_SEQ  NUMBER(13) -- 거래일련번호(거래내역 PK)
);
/

-- CHANGE BOND IR INFO TYPE
CREATE OR REPLACE TYPE CHANGE_BOND_IR_INFO_TYPE AS OBJECT (
  TRD_DATE  CHAR(8)       -- 거래일자(잔고 PK)
, FUND_CODE CHAR(10)      -- 펀드코드(잔고 PK)
, BOND_CODE CHAR(12)      -- 종목코드(잔고 PK)
, BUY_DATE  CHAR(8)       -- 매수일자(잔고 PK)
, BUY_PRICE NUMBER(13)    -- 매수단가(잔고 PK)
, BALAN_SEQ NUMBER(13)    -- 잔고일련번호(잔고 PK)
, BOND_IR   NUMBER(15,12) -- 표면이자율
);
/

-- Cash Flow Type (동일 기준일 SEQ 고려)
CREATE OR REPLACE TYPE CF_TYPE AS OBJECT (
 BASE_DATE      CHAR(8)            /* 기준일   */
,FACE_AMT       NUMBER(20,2)       /* 액면금액              */
,TOT_DAYS       NUMBER(10)         /* 총일수(기준일-취득일) */
,INT_DAYS       NUMBER(10)         /* 이자일수              */
,INT_AMT        NUMBER(20,2)       /* 이자금액              */
,PRC_AMT        NUMBER(20,2)       /* 원금액                */
,CUR_VALUE      NUMBER(20,2)       /* 현재가치(유효이자로 계산한 현재가치금액 */
)
/
-- SangGak Flow Type (동일 기준일 SEQ 고려)
CREATE OR REPLACE TYPE SGF_TYPE AS OBJECT(
 BASE_DATE       CHAR(8)           /* 기준일 */
,SEQ             NUMBER            /* 동일 기준일에 2개이상의 EVENT발생시에 발생순번 */
,SANGGAK_TYPE    CHAR(1)           /* 상각 TYPE : 1.매수, 2.매도, 3.이자수령, 4.만기, 5.월결산, 6.기결산, 7.손상, 8.회복 */
,DAYS            NUMBER(10)        /* 상각일수                      */
,FACE_AMT        NUMBER(20,2)      /* 액면금액                      */
,BF_BOOK_AMT     NUMBER(20,2)      /* 기초장부금액                  */
,EIR_INT_AMT     NUMBER(20,2)      /* 유효이자                      */
,FACE_INT_AMT    NUMBER(20,2)      /* 액면이자                      */
,SANGGAK_AMT     NUMBER(20,2)      /* 상각금액(유효이자-액면이자)   */
,AF_BOOK_AMT     NUMBER(20,2)      /* 기말장부금액                  */
,MI_SANGGAK_AMT  NUMBER(20,2)      /* 미상각잔액                    */
,BF_BOOK_AMT_EIR NUMBER(20,2)      /* 기초장부금액(유효이자계산용)  */
,REAL_INT_AMT    NUMBER(20,2)      /* 실이자금액(실발생기준)        */
,SANGGAK_AMT_EIR NUMBER(20,2)      /* 상각금액(유효이자-실이자금액) */
,AF_BOOK_AMT_EIR NUMBER(20,2)      /* 기말장부금액(유효이자계산용)  */
)
/
  -- EVENT INFO TYPE
CREATE OR REPLACE TYPE EVENT_INFO_TYPE AS OBJECT (
    FUND_CODE      CHAR(10)      -- 펀드코드 (채권잔고의 PK)
   ,BOND_CODE      CHAR(12)      -- 종목코드(채권잔고의 PK)
   ,BUY_DATE       CHAR(8)       -- Buy Date (채권잔고의 PK)
   ,BUY_PRICE      NUMBER(13)    -- 매수단가 (채권잔고의 PK)
   ,BALAN_SEQ      NUMBER(13)    -- 잔고일련번호(채권잔고의 PK)
   ,EVENT_DATE     CHAR(8)       -- 이벤트일 (PK)  -- 결제일기준
   ,EVENT_SEQ      NUMBER        -- 이벤트SEQ(PK)  -- 취소시만 SET
   ,EVENT_TYPE     CHAR(1)       -- Event 종류: 1.매수, 2.매도(전환), 3.금리변동, 4.손상
   ,DL_UV          NUMBER(20)    -- 거래단가 (매수/매도시 SET)
   ,DL_QT          NUMBER(20)    -- 거래수량 (매수,매도시 SET)
   ,IR             NUMBER(10,5)  -- 표면이자율
   ,SELL_RT        NUMBER(10,5)  -- 매도율
  );


-- Cash Flow Collection
CREATE OR REPLACE TYPE TABLE_CF AS TABLE OF CF_TYPE
/
-- SangGak Flow Collection
CREATE OR REPLACE TYPE TABLE_SGF AS TABLE OF SGF_TYPE
/

-- Event 결과 INFO (Event 결과정보) - Nested Table, TABLE_CF, TABLE_SGF을 Nested Table 필드로 가짐
CREATE TABLE EVENT_RESULT_EIR (
 FUND_CODE      CHAR(10)   NOT NULL  -- 펀드코드    (채권잔고의 PK) 
,BOND_CODE      CHAR(12)   NOT NULL  -- Bond Code   (채권잔고의 PK) 
,BUY_DATE       CHAR(8)    NOT NULL  -- Buy Date    (채권잔고의 PK) 
,BUY_PRICE      NUMBER(13) NOT NULL  -- 매수단가    (채권잔고의 PK) 
,BALAN_SEQ      NUMBER(13) NOT NULL  -- 잔고일련번호(채권잔고의 PK)
,EVENT_DATE     CHAR(8)    NOT NULL  -- 이벤트일 (PK) - 결제일
,EVENT_SEQ      NUMBER     NOT NULL  -- 이벤트 SEQ (PK : 동일한 EVENT일에 2개이상의 동일한 EVENT 발생시를 고려함)
,EVENT_TYPE     CHAR(1)    NOT NULL  -- Event 종류 : 1.매수, 2.매도(전환), 3.금리변동, 4.손상
,IR             NUMBER(10,5)         -- 표면이자율     
,EIR            NUMBER(15,10)        -- 유효이자율    
,TOT_INT        NUMBER(22)           -- 총이자금액
,ACCRUED_INT    NUMBER(22)           -- 경과이자
,SANGGAK_AMT    NUMBER(22)           -- 상각금액
,MI_SANGGAK_AMT NUMBER(22)           -- 미상각금액
,CF_LIST        TABLE_CF             -- Cash Flow List 
,SGF_LIST       TABLE_SGF            -- SangGakFlow List 
) NESTED TABLE "CF_LIST" STORE AS "EVENT_RESULT_EIR_CF_LIST"
  NESTED TABLE "SGF_LIST" STORE AS "EVENT_RESULT_EIR_SGF_LIST" 
/

CREATE UNIQUE INDEX EVENT_RESULT_EIR_PK ON EVENT_RESULT_EIR(
FUND_CODE ASC, BOND_CODE ASC, BUY_DATE ASC, BUY_PRICE ASC, BALAN_SEQ ASC, EVENT_DATE ASC, EVENT_SEQ ASC
)
/