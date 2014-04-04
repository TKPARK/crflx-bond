CREATE OR REPLACE FUNCTION ISS.FN_INIT_BOND_TRADE
  RETURN BOND_BALANCE%ROWTYPE AS
  T_BOND_TRADE BOND_TRADE%ROWTYPE;
BEGIN
  T_BOND_TRADE.TRD_DATE            := ''; -- 거래일자
  T_BOND_TRADE.TRD_SEQ             := 0;  -- 거래일련번호
  T_BOND_TRADE.FUND_CODE           := ''; -- 펀드코드
  T_BOND_TRADE.BOND_CODE           := ''; -- 종목코드
  T_BOND_TRADE.BUY_DATE            := ''; -- 매수일자
  T_BOND_TRADE.BUY_PRICE           := 0;  -- 매수단가
  T_BOND_TRADE.BALAN_SEQ           := 0;  -- 잔고일련번호
  T_BOND_TRADE.TRD_TYPE_CD         := ''; -- 매매유형코드(1.인수, 2.직매수, 3.직매도, 4.상환)
  T_BOND_TRADE.GOODS_BUY_SELL_SECT := ''; -- 상품매수매도구분(1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복)
  T_BOND_TRADE.STT_TERM_SECT       := ''; -- 결제기간구분(1.당일, 2.익일)
  T_BOND_TRADE.SETL_DATE           := ''; -- 결제일자
  T_BOND_TRADE.EXPR_DATE           := ''; -- 만기일자
  T_BOND_TRADE.TRD_PRICE           := 0;  -- 매매단가
  T_BOND_TRADE.TRD_QTY             := 0;  -- 매매수량
  T_BOND_TRADE.TRD_FACE_AMT        := 0;  -- 매매액면
  T_BOND_TRADE.TRD_AMT             := 0;  -- 매매금액
  T_BOND_TRADE.TRD_NET_AMT         := 0;  -- 매매정산금액
  T_BOND_TRADE.TOT_INT             := 0;  -- 총이자금액
  T_BOND_TRADE.ACCRUED_INT         := 0;  -- 경과이자
  T_BOND_TRADE.BTRM_UNPAID_INT     := 0;  -- 전기미수이자
  T_BOND_TRADE.TTRM_BOND_INT       := 0;  -- 당기채권이자
  T_BOND_TRADE.TOT_DCNT            := 0;  -- 총일수
  T_BOND_TRADE.SRV_DCNT            := 0;  -- 잔존일수
  T_BOND_TRADE.LPCNT               := 0;  -- 경과일수
  T_BOND_TRADE.HOLD_DCNT           := 0;  -- 보유일수
  T_BOND_TRADE.BOND_EIR            := 0;  -- 유효이자율
  T_BOND_TRADE.BOND_IR             := 0;  -- 표면이자율
  T_BOND_TRADE.SANGGAK_AMT         := 0;  -- 상각금액
  T_BOND_TRADE.MI_SANGGAK_AMT      := 0;  -- 미상각금액
  T_BOND_TRADE.BOOK_AMT            := 0;  -- 장부금액
  T_BOND_TRADE.BOOK_PRC_AMT        := 0;  -- 장부원가
  T_BOND_TRADE.TRD_PRFT            := 0;  -- 매매이익
  T_BOND_TRADE.TRD_LOSS            := 0;  -- 매매손실
  T_BOND_TRADE.BTRM_EVAL_PRFT      := 0;  -- 전기평가이익
  T_BOND_TRADE.BTRM_EVAL_LOSS      := 0;  -- 전기평가손실
  T_BOND_TRADE.TXSTD_AMT           := 0;  -- 과표금액
  T_BOND_TRADE.CORP_TAX            := 0;  -- 선급법인세
  T_BOND_TRADE.UNPAID_CORP_TAX     := 0;  -- 미지급법인세
  
  RETURN T_BOND_TRADE;
END;