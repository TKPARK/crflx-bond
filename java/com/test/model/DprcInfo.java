package com.test.model;

public class DprcInfo {
	// 상각액 상각표
	public String cfDate;				// CF일자
	public int dprcType;				// 상각종류(1:매수, 2:이자, 3:결산, 4:만기)
	public String faceAmt = "0";		// 액면금액
	public int dprcDays = 0;			// 상각일수
	public String openingBookAmt = "0";	// 기초장부금액
	public String effectiveInt = "0";	// 유효이자
	public String faceInt = "0";		// 액면이자
	public String dprcAmt = "0";		// 상각액
	public String closingBookAmt = "0";	// 기말장부금액
	public String unDprcBal = "0";		// 미상각잔액
	
	// 유효이자 상각표
	public String _openingBookAmt = "0";// 기초장부금액
	public String _effectiveInt = "0";	// 유효이자
	public String _faceInt = "0";		// 액면이자(발생)
	public String _dprcAmt = "0";		// 상각액
	public String _closingBookAmt = "0";// 기말장부금액
	
	@Override
	public String toString() {
		return "DprcInfo [cfDate=" + cfDate + ", dprcType=" + dprcType
				+ ", faceAmt=" + faceAmt + ", dprcDays=" + dprcDays
				+ ", openingBookAmt=" + openingBookAmt + ", effectiveInt="
				+ effectiveInt + ", faceInt=" + faceInt + ", dprcAmt="
				+ dprcAmt + ", closingBookAmt=" + closingBookAmt
				+ ", unDprcBal=" + unDprcBal + ", _openingBookAmt="
				+ _openingBookAmt + ", _effectiveInt=" + _effectiveInt
				+ ", _faceInt=" + _faceInt + ", _dprcAmt=" + _dprcAmt
				+ ", _closingBookAmt=" + _closingBookAmt + "]";
	}
}
