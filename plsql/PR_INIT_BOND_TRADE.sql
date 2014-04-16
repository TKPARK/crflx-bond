CREATE OR REPLACE PROCEDURE ISS.PR_INIT_BOND_TRADE (
  I_BOND_TRADE IN OUT BOND_TRADE%ROWTYPE
) IS
BEGIN
  I_BOND_TRADE.TRD_DATE            := ''; -- 거래일자
  I_BOND_TRADE.TRD_SEQ             := 0;  -- 거래일련번호
  I_BOND_TRADE.FUND_CODE           := ''; -- 펀드코드
  I_BOND_TRADE.BOND_CODE           := ''; -- 종목코드
  I_BOND_TRADE.BUY_DATE            := ''; -- 매수일자
  I_BOND_TRADE.BUY_PRICE           := 0;  -- 매수단가
  I_BOND_TRADE.BALAN_SEQ           := 0;  -- 잔고일련번호
  I_BOND_TRADE.TRD_TYPE_CD         := ''; -- 매매유형코드(1.인수, 2.직매수, 3.직매도, 4.상환)
  I_BOND_TRADE.GOODS_BUY_SELL_SECT := ''; -- 상품매수매도구분(1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복)
  I_BOND_TRADE.STT_TERM_SECT       := ''; -- 결제기간구분(1.당일, 2.익일)
  I_BOND_TRADE.SETL_DATE           := ''; -- 결제일자
  I_BOND_TRADE.EXPR_DATE           := ''; -- 만기일자
  I_BOND_TRADE.EVENT_DATE          := ''; -- 이벤트일 (PK)
  I_BOND_TRADE.EVENT_SEQ           := 0;  -- 이벤트 SEQ
  I_BOND_TRADE.TRD_PRICE           := 0;  -- 매매단가
  I_BOND_TRADE.TRD_QTY             := 0;  -- 매매수량
  I_BOND_TRADE.TRD_FACE_AMT        := 0;  -- 매매액면
  I_BOND_TRADE.TRD_AMT             := 0;  -- 매매금액
  I_BOND_TRADE.TRD_NET_AMT         := 0;  -- 매매정산금액
  I_BOND_TRADE.TOT_INT             := 0;  -- 총이자금액
  I_BOND_TRADE.ACCRUED_INT         := 0;  -- 경과이자
  I_BOND_TRADE.BTRM_UNPAID_INT     := 0;  -- 전기미수이자
  I_BOND_TRADE.TTRM_BOND_INT       := 0;  -- 당기채권이자
  I_BOND_TRADE.TOT_DCNT            := 0;  -- 총일수
  I_BOND_TRADE.SRV_DCNT            := 0;  -- 잔존일수
  I_BOND_TRADE.LPCNT               := 0;  -- 경과일수
  I_BOND_TRADE.HOLD_DCNT           := 0;  -- 보유일수
  I_BOND_TRADE.BOND_EIR            := 0;  -- 유효이자율
  I_BOND_TRADE.BOND_IR             := 0;  -- 표면이자율
  I_BOND_TRADE.DSCT_SANGGAK_AMT    := 0;  -- 할인상각금액
  I_BOND_TRADE.EX_CHA_SANGGAK_AMT  := 0;  -- 할증상각금액
  I_BOND_TRADE.MI_SANGGAK_AMT      := 0;  -- 미상각금액
  I_BOND_TRADE.BOOK_AMT            := 0;  -- 장부금액
  I_BOND_TRADE.BOOK_PRC_AMT        := 0;  -- 장부원가
  I_BOND_TRADE.TRD_PRFT            := 0;  -- 매매이익
  I_BOND_TRADE.TRD_LOSS            := 0;  -- 매매손실
  I_BOND_TRADE.BTRM_EVAL_PRFT      := 0;  -- 전기평가이익
  I_BOND_TRADE.BTRM_EVAL_LOSS      := 0;  -- 전기평가손실
  I_BOND_TRADE.TXSTD_AMT           := 0;  -- 과표금액
  I_BOND_TRADE.CORP_TAX            := 0;  -- 선급법인세
  I_BOND_TRADE.UNPAID_CORP_TAX     := 0;  -- 미지급법인세
  
END;