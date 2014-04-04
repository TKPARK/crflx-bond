CREATE OR REPLACE PROCEDURE ISS.PR_NEW_BOND_EVENT (
  -- 거래내역ROWTPYE을 I/O로 사용(서비스 <-> 프로시저)
  I_BOND_TRADE IN OUT BOND_TRADE%ROWTYPE -- ROWTYPE : 거래내역
) IS
  --
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;   -- ROWTYPE : 잔고
  T_EVENT_INFO   EVENT_INFO_TYPE;        -- TYPE : EVENT_INFO_TYPE
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증(INPUT 필드)
  --   TRD_DATE            -- 거래일자(PK)
  --   FUND_CODE           -- 펀드코드
  --   BOND_CODE           -- 종목코드
  --   BUY_DATE            -- 매수일자
  --   BUY_PRICE           -- 매수단가
  --   TRD_TYPE_CD         -- 매매유형코드(1.인수, 2.직매수, 3.직매도, 4.상환)
  --   GOODS_BUY_SELL_SECT -- 상품매수매도구분(1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복)
  --   STT_TERM_SECT       -- 결제기간구분(1.당일, 2.익일)
  --   TRD_PRICE           -- 매매단가
  --   TRD_QTY             -- 매매수량
  --   BOND_IR             -- 표면이자율
  ----------------------------------------------------------------------------------------------------
  -- 매매단가
  IF I_BOND_TRADE.TRD_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '매매단가 오류');
  END IF;
  -- 매매수량
  IF I_BOND_TRADE.TRD_QTY <= 0 THEN
    PCZ_RAISE(-20999, '매매수량 오류');
  END IF;
  -- 표면이자율
  IF I_BOND_TRADE.BOND_IR <= 0 THEN
    PCZ_RAISE(-20999, '표면이자율 오류');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)변수초기화
  --   * Object들을 초기화 및 Default값으로 설정함
  --   * 거래내역, 잔고 TABLE SEQ 채번
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO := FN_INIT_EVENT_INFO();
  T_BOND_BALANCE := FN_INIT_BOND_BALANCE();
  
  -- 거래내역 거래일련번호(PK) 채번
  SELECT NVL(MAX(A.TRD_SEQ), 0) + 1 AS TRD_SEQ
    INTO I_BOND_TRADE.TRD_SEQ
    FROM BOND_TRADE A
   WHERE A.TRD_DATE  = I_BOND_TRADE.TRD_DATE;
  
  -- 잔고 잔고일련번호(PK) 채번
  SELECT NVL(MAX(A.BALAN_SEQ), 0) + 1 AS BALAN_SEQ
    INTO I_BOND_TRADE.BALAN_SEQ
    FROM BOND_BALANCE A
   WHERE A.BIZ_DATE  = I_BOND_TRADE.TRD_DATE
     AND A.FUND_CODE = I_BOND_TRADE.FUND_CODE
     AND A.BOND_CODE = I_BOND_TRADE.BOND_CODE
     AND A.BUY_DATE  = I_BOND_TRADE.BUY_DATE
     AND A.BUY_PRICE = I_BOND_TRADE.BUY_PRICE;
  
  -- 결제일자 RULE
  -- 1.당일 : 결제일자 = 매수일자
  -- 2.익일 : 결제일자 = 매수일자 + 1일
  IF I_BOND_TRADE.STT_TERM_SECT = '1' THEN
    I_BOND_TRADE.SETL_DATE    := I_BOND_TRADE.BUY_DATE; -- 결제일자
  ELSIF I_BOND_TRADE.STT_TERM_SECT = '2' THEN
    I_BOND_TRADE.SETL_DATE    := TO_CHAR(TO_DATE(I_BOND_TRADE.BUY_DATE, 'YYYYMMDD')+1), 'YYYYMMDD'); -- 결제일자
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 3-1)INPUT 설정
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := I_BOND_TRADE.FUND_CODE;           -- 펀드코드(채권잔고의 PK)
  T_EVENT_INFO.BOND_CODE  := I_BOND_TRADE.BOND_CODE;           -- 종목코드(채권잔고의 PK)
  T_EVENT_INFO.BUY_DATE   := I_BOND_TRADE.BUY_DATE;            -- Buy Date(채권잔고의 PK)
  T_EVENT_INFO.BUY_PRICE  := I_BOND_TRADE.BUY_PRICE;           -- 매수단가(채권잔고의 PK)
  T_EVENT_INFO.BALAN_SEQ  := I_BOND_TRADE.BALAN_SEQ;           -- 잔고일련번호(채권잔고의 PK)
  T_EVENT_INFO.EVENT_DATE := I_BOND_TRADE.SETL_DATE;           -- 이벤트일(PK)
  T_EVENT_INFO.EVENT_TYPE := I_BOND_TRADE.GOODS_BUY_SELL_SECT; -- Event 종류(1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복)
  T_EVENT_INFO.DL_UV      := I_BOND_TRADE.BUY_PRICE;           -- 거래단가
  T_EVENT_INFO.DL_QT      := I_BOND_TRADE.TRD_QTY;             -- 거래수량
  T_EVENT_INFO.STL_DT_TP  := I_BOND_TRADE.STT_TERM_SECT;       -- 결제일구분(1.당일, 2.익일)
  T_EVENT_INFO.IR         := I_BOND_TRADE.BOND_IR;             -- 표면이자율
  
  ----------------------------------------------------------------------------------------------------
  -- 3-2)최초 매수 이벤트 처리 프로시져 호출
  --   * 경과이자, 현금흐름 생성, EIR산출, 상각표 생성 처리
  ----------------------------------------------------------------------------------------------------
  PKG_EIR_NESTED_NSC.PR_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)기준정보 계산
  --   * T_EVENT_RESULT 데이터를 가지고 기준정보 설정
  --   * 기준정보에 필요한 조회 및 계산 로직 등을 구현
  ----------------------------------------------------------------------------------------------------
  I_BOND_TRADE.TOT_INT      := T_EVENT_RESULT.ACCRUED_INT;                                -- 총이자금액
  I_BOND_TRADE.ACCRUED_INT  := T_EVENT_RESULT.ACCRUED_INT;                                -- 경과이자
  I_BOND_TRADE.EXPR_DATE    := ; -- 만기일자
  I_BOND_TRADE.BOND_EIR     := T_EVENT_RESULT.EIR;                                        -- 유효이자율
  I_BOND_TRADE.TRD_FACE_AMT := I_BOND_TRADE.TRD_QTY * 1000;                               -- 매매액면(수량 * 1000)
  I_BOND_TRADE.TRD_AMT      := TRUNC(I_BOND_TRADE.TRD_PRICE * I_BOND_TRADE.TRD_QTY / 10); -- 매매금액(수량 * 단가 / 10)
  I_BOND_TRADE.TRD_NET_AMT  := I_BOND_TRADE.TRD_AMT-I_BOND_TRADE.ACCRUED_INT;             -- 매매정산금액(매매금액 - 경과이자)
  I_BOND_TRADE.BOOK_AMT     := I_BOND_TRADE.TRD_NET_AMT;                                  -- 장부금액
  I_BOND_TRADE.BOOK_PRC_AMT := I_BOND_TRADE.TRD_NET_AMT;                                  -- 장부원가
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5-1)거래내역 등록
  ----------------------------------------------------------------------------------------------------
  INSERT INTO BOND_TRADE VALUES I_BOND_TRADE;
  
  ----------------------------------------------------------------------------------------------------
  -- 5-2)잔고 등록
  ----------------------------------------------------------------------------------------------------
  -- PK
  T_BOND_BALANCE.BIZ_DATE       := T_BOND_TRADE.TRD_DATE;         -- 영업일자(PK)
  T_BOND_BALANCE.FUND_CODE      := T_BOND_TRADE.FUND_CODE;        -- 펀드코드(PK)
  T_BOND_BALANCE.BOND_CODE      := T_BOND_TRADE.BOND_CODE;        -- 종목코드(PK)
  T_BOND_BALANCE.BUY_DATE       := T_BOND_TRADE.BUY_DATE;         -- 매수일자(PK)
  T_BOND_BALANCE.BUY_PRICE      := T_BOND_TRADE.BUY_PRICE;        -- 매수단가(PK)
  T_BOND_BALANCE.BALAN_SEQ      := T_BOND_TRADE.BALAN_SEQ;        -- 잔고일련번호(PK)
  
  -- VALUE
  T_BOND_BALANCE.BOND_IR        := T_BOND_TRADE.BOND_IR;          -- IR
  T_BOND_BALANCE.BOND_EIR       := T_BOND_TRADE.BOND_EIR;         -- EIR
  
  -- 잔고수량 RULE
  -- 1.당일(매수 100)
  --   ex)총잔고수량 = 100, 당일잔고수량 = 100, 익일잔고수량 = 100;
  -- 2.익일(매수 100)
  --   ex)총잔고수량 = 100, 당일잔고수량 =   0, 익일잔고수량 = 100;
  IF I_BOND_TRADE.STT_TERM_SECT = '1' THEN
    T_BOND_BALANCE.TOT_QTY        := T_BOND_TRADE.TRD_QTY;        -- 총잔고수량
    T_BOND_BALANCE.TDY_AVAL_QTY   := T_BOND_TRADE.TRD_QTY;        -- 당일가용수량
    T_BOND_BALANCE.NDY_AVAL_QTY   := T_BOND_TRADE.TRD_QTY;        -- 익일가용수량
  ELSIF I_BOND_TRADE.STT_TERM_SECT = '2' THEN
    T_BOND_BALANCE.TOT_QTY        := T_BOND_TRADE.TRD_QTY;        -- 총잔고수량
    T_BOND_BALANCE.TDY_AVAL_QTY   := 0;                           -- 당일가용수량
    T_BOND_BALANCE.NDY_AVAL_QTY   := T_BOND_TRADE.TRD_QTY;        -- 익일가용수량
  END IF;
  T_BOND_BALANCE.BOOK_AMT       := T_BOND_TRADE.BOOK_AMT;         -- 장부금액
  T_BOND_BALANCE.BOOK_PRC_AMT   := T_BOND_TRADE.BOOK_PRC_AMT;     -- 장부원가
  T_BOND_BALANCE.ACCRUED_INT    := T_BOND_TRADE.ACCRUED_INT;      -- 경과이자
  T_BOND_BALANCE.MI_SANGGAK_AMT := T_EVENT_RESULT.MI_SANGGAK_AMT; -- 미상각금액(미상각이자)
  T_BOND_BALANCE.DRT_BUY_QTY    := T_BOND_TRADE.TRD_QTY;          -- 직매수수량

  INSERT INTO BOND_BALANCE VALUES T_BOND_BALANCE;
  
  
END;