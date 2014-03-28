package com.test.common;

import java.math.BigDecimal;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.Locale;

import com.test.model.BondInfo;
import com.test.model.CashFlowInfo;
import com.test.model.DprcInfo;
import com.test.model.EventInfo;

public class Worker {
	
	
	/**
	 * 경과이자 계산
	 * @param bondInfo
	 * @param eventInfo
	 */
	public static String calAccruedInt(BondInfo bondInfo, EventInfo eventInfo) {
		String accruedInt = "0";
        switch(bondInfo.bondType) {
        case 1:
        	// 할인채
        	accruedInt = Worker.calDiscountDebenture(bondInfo, eventInfo);
        	break;
        case 2:
        	// 이표채
        	accruedInt = Worker.calCouponBond(bondInfo, eventInfo);
        	break;
        case 3:
        	// 단리채
        	accruedInt = Worker.calSimpleInterestBond(bondInfo, eventInfo);
        	break;
        case 4:
        	// 복리채
        	accruedInt = Worker.calCompoundBond(bondInfo, eventInfo);
        	break;
        }
        
        return accruedInt;
	}
	
	
	/**
	 * 할인채(discount debenture)
	 * @param bondInfo
	 * @return 0
	 */
	public static String calDiscountDebenture(BondInfo bondInfo, EventInfo eventInfo) {
		return "0";
	}
	
	
	/**
	 * 이표채(단리)(coupon bond)
	 * @param bondInfo
	 * @param eventInfo
	 * @return 액면금액 * 이자율 * (취득일 - 직전이자지급일) / 365
	 */
	public static String calCouponBond(BondInfo bondInfo, EventInfo eventInfo) {
		// 1.직전 이자 지급일 계산
		//   1-1. 발행일자, 취득일 -> Calendar형으로 변환
		String beforeIntDate = bondInfo.issueDate; // 직전 이자 지급일
		Calendar calIssueDate = strDtToCal(bondInfo.issueDate); // 발행일자
		Calendar calEventDate = strDtToCal(eventInfo.eventDate); // 취득일
		
		//   2-2. 발행일자에 월이자지급주기를 더하며 취득일 직전이자지급일 계산
		while(calEventDate.after(calIssueDate)) {
			beforeIntDate = calToStrDt(calIssueDate);
			calIssueDate.add(Calendar.MONTH, bondInfo.intCycle);
		}
		
		// 2.(취득일-직전이자지급일) 계산
		int intDays = daysBetween(beforeIntDate, eventInfo.eventDate);
		
		// 3.경과이자 계산
		BigDecimal accruedInt = strToDecimal(bondInfo.faceAmt)
									.multiply(strToDecimal(bondInfo.ir))
									.multiply(intToDecimal(intDays))
									.divide(strToDecimal("365"), 2, BigDecimal.ROUND_DOWN);
		return accruedInt.toString();
	}
	
	
	/**
	 * 단리채(만기)(simple interest bond)
	 * @param bondInfo
	 * @param eventInfo
	 * @return 액면금액 * 이자율 * (취득일 - 발행일) / 365
	 */
	public static String calSimpleInterestBond(BondInfo bondInfo, EventInfo eventInfo) {
		// 1.(취득일 - 발행일) 계산
		int intDays = daysBetween(bondInfo.issueDate, eventInfo.eventDate);
		
		// 2.경과이자 계산
		BigDecimal accruedInt = strToDecimal(bondInfo.faceAmt)
									.multiply(strToDecimal(bondInfo.ir))
									.multiply(intToDecimal(intDays))
									.divide(strToDecimal("365"), 2, BigDecimal.ROUND_DOWN);
		return accruedInt.toString();
	}
	

	/**
	 * 복리채(compound bond)
	 * @param bondInfo
	 * @param eventInfo
	 * @return 액면금액 * (1+IR/년지급횟수)^복리횟수
	 * ※복리횟수 = (발행일~직전이자기준일까지의 횟수) + (취득일-직전이자기준일) / (직후이자기준일-직전이자기준일)
	 */
	public static String calCompoundBond(BondInfo bondInfo, EventInfo eventInfo) {
		// 1.복리횟수 계산
		//   1-1. 이자발생횟수, 직전이자지급일, 직후이자지급일 계산
		int intCnt = 0; // 이자 발생 횟수
		String beforeIntDate = ""; // 직전 이자 지급일
		String afterIntDate = ""; // 직후 이자 지급일
		Calendar calIssueDate = strDtToCal(bondInfo.issueDate); // 발행일자
		Calendar calEventDate = strDtToCal(eventInfo.eventDate); // 취득일
		while(calEventDate.after(calIssueDate)) {
			intCnt++;
			beforeIntDate = calToStrDt(calIssueDate);
			calIssueDate.add(Calendar.MONTH, bondInfo.intCycle);
			afterIntDate = calToStrDt(calIssueDate);
		}
		intCnt = intCnt - 1;

		//   1-2.(취득일-직전이자기준일) 계산
		int intDays1 = daysBetween(beforeIntDate, eventInfo.eventDate);

		//   1-3.(직후이자기준일-직전이자기준일) 계산
		int intDays2 = daysBetween(beforeIntDate, afterIntDate);
		
		//   1-4. 복리횟수 계산
		BigDecimal b = intToDecimal(intDays1)
							.divide(intToDecimal(intDays2), 10, BigDecimal.ROUND_DOWN)
							.add(intToDecimal(intCnt));
		
		// 2.경과이자 계산
		BigDecimal a = strToDecimal(bondInfo.ir)
							.divide(intToDecimal(12 / bondInfo.intCycle), 10, BigDecimal.ROUND_DOWN)
							.add(strToDecimal("1"));
		
		double powAb = Math.pow(a.doubleValue(), b.doubleValue());
		BigDecimal accruedInt = strToDecimal(bondInfo.faceAmt)
								.multiply(strToDecimal(Double.toString(powAb)))
								.subtract(strToDecimal(bondInfo.faceAmt))
								.setScale(2, BigDecimal.ROUND_DOWN);
		
		return accruedInt.toString();
	}
	
	
	/**
	 * Cash Flow
	 * @param bondInfo
	 * @param eventInfo
	 * @return ArrayList
	 */
	public static void calCashFlow(BondInfo bondInfo, EventInfo eventInfo) {
		
		// 1.add 취득정보
		CashFlowInfo cfInfo = new CashFlowInfo();
		cfInfo.cfIssueDate = eventInfo.eventDate; // 현금흐름발생일
		cfInfo.totalAmt = eventInfo.evetAmt; // 취득금액
		eventInfo.cfList.add(cfInfo);
		
		// 2.취득후 최초 이자 지급일 계산
		String afterIntDate = ""; // 직후 이자 지급일
		Calendar calIssueDate = strDtToCal(bondInfo.issueDate); // 발행일자
		Calendar calEventDate = strDtToCal(eventInfo.eventDate); // 취득일
		while(calEventDate.after(calIssueDate)) {
			calIssueDate.add(Calendar.MONTH, bondInfo.intCycle);
			afterIntDate = calToStrDt(calIssueDate);
		}
		
		// 3.직후이자지급일 ~ 만기일까지 CashFlow loop 실행
		String tempCfIssueDate = eventInfo.eventDate;
		String eventDate = eventInfo.eventDate;
		Calendar calAfterIntDate = strDtToCal(afterIntDate); // 직후이자지급일
		Calendar calExpireDate = strDtToCal(bondInfo.expireDate); // 만기일
		while(calExpireDate.after(calAfterIntDate) || calExpireDate.equals(calAfterIntDate)) {
			CashFlowInfo item = new CashFlowInfo();
			item.cfIssueDate = calToStrDt(calAfterIntDate); // 현금흐름발생일
			item.intDays = daysBetween(tempCfIssueDate, item.cfIssueDate); // 이자일수
			item.addDays = daysBetween(eventDate, item.cfIssueDate); // 누적일수
			
			// 이표채 경과이자 함수를 재사용하기위해 발생일, 취득일, 취득금액 다시 설정함
			BondInfo bond = new BondInfo();
			bond.faceAmt = bondInfo.faceAmt;
			bond.issueDate = tempCfIssueDate;
			bond.intCycle = bondInfo.intCycle;
			bond.ir = bondInfo.ir;
			
			EventInfo event = new EventInfo();
			event.eventDate = item.cfIssueDate;

			item.intCashFlowAmt = calCouponBond(bond, event); // 이자CF금액
			
			if(item.cfIssueDate.equals(bondInfo.expireDate)) {
				item.priCashFlowAmt = bondInfo.faceAmt; // 원금CF금액
			}
			
			// 금액(합계)
			item.totalAmt = strToDecimal(item.intCashFlowAmt)
								.add(strToDecimal(item.priCashFlowAmt))
								.setScale(2, BigDecimal.ROUND_DOWN)
								.toString();
			
			// 이자일수를 구하기 위해 따로 저장함
			tempCfIssueDate = item.cfIssueDate;
			
			// CashFlow List에 추가
			eventInfo.cfList.add(item);
			
			// 다음 현금흐름발생일로 이동
			calAfterIntDate.add(Calendar.MONTH, bondInfo.intCycle);
		}
	}
	
	
	/**
	 * EIR 찾기
	 * 1.최초 액면이자율을 IR로 적용하여 현재가치의 합(SUM(CV))을 구한다.
	 * 2.차이금액 = SUM(CV) ? 장부금액(취득금액)
	 * 3.IF 차이금액 > 0 THEN
	 *      IR을 한단계(특정단위)씩 높이면서 차이금액 < 0 인 IR을 찾는다.  위 계산식에 의해 근사 IR을 구한다.
	 *   ELSIF 차이금액 < 0 THEN
	 *      IR을 한단계(특정단위)씩 낮추면서 차이금액 > 0 인 IR을 찾는다. 위 계산식에 의해 근사 IR을 구한다.
	 * 
	 * -특정단위(최초 1%(0.01)부터 계속 낮추어가며 0.001, 0,0001, 0.00001,.. 소수10자리정도)가며 차이금액이 0가 되는 IR을 찾으면 그 IR이 EIR이 된다.
	 *  소수2자리 절사등의 단수차에 의해 소수 10자리까지 근사해도 차이금액이 남으면 차이금액이 0.05$(오차범위) 이하이면 해당 IR을 EIR로 한다.
	 * -현재가치(Current Value) = 현금흐름합계/POWER(1 + EIR, 총일수/365), 소수2자리 절사
	 * @param bondInfo
	 * @param eventInfo
	 * @param cfList
	 * @return
	 */
	public static void calEir(BondInfo bondInfo, EventInfo eventInfo) {
		// EIR 찾기 RULE
		// 1.최초 IR은 액면이자율을 IR, 가감단위는 최초 1%(0.01)으로 설정
		// 2.근사값 EIR 찾기 함수 호출(Trial and error method)
		// 3.리턴받은 근사값 EIR을 가지고 값 검증 실행
		// 4.(현재가치의 합 - 취득금액) == 0 이면 loop를 빠져나온다
		//   0이 아니면 EIR를 IR로 재설정하고, 가감단위는 한단계 밑으로 내린후 -> 2.근사값 EIR 찾기 함수 호출
		
		BigDecimal ir = new BigDecimal(bondInfo.ir); // 액면이자율 설정
		BigDecimal unit = new BigDecimal("0.01"); // 가감 단위
		
		for(int i=0; i<10; i++) {
			// 근사값 EIR 찾기 함수 호출
			eventInfo.eir = calTrialAndError(eventInfo, ir, unit);
			
			// 값 검증
			BigDecimal sumCv = new BigDecimal("0");
			for(int j=1; j<eventInfo.cfList.size(); j++) {
				// 현재가치 및 현재가치의 합 구함
				BigDecimal a = strToDecimal("1").add(strToDecimal(eventInfo.eir));
				BigDecimal b = intToDecimal(eventInfo.cfList.get(j).addDays)
									.divide(strToDecimal("365"), 10, BigDecimal.ROUND_DOWN);
				double powAb = Math.pow(a.doubleValue(), b.doubleValue());
				
				BigDecimal cv = strToDecimal(eventInfo.cfList.get(j).totalAmt)
									.divide(strToDecimal(Double.toString(powAb)), 2, BigDecimal.ROUND_DOWN);
				eventInfo.cfList.get(j).cv = cv.toString();
				sumCv = sumCv.add(cv);
			}
			
			// 현재가치의 합과 취득금액의 차이금액을 구함
			BigDecimal diffAmt = sumCv.subtract(strToDecimal(eventInfo.evetAmt));
			if(diffAmt.compareTo(strToDecimal("0")) == 0) {
				break;
			}
			
			// 재설정
			ir = strToDecimal(eventInfo.eir);
			unit = unit.divide(strToDecimal("10"), 10, BigDecimal.ROUND_DOWN);
		}
	}
	
	
	/**
	 * 근사값 EIR 찾기
	 * @param cfList
	 * @param ir
	 * @param unitm
	 * @param eventInfo
	 * @return
	 */
	public static String calTrialAndError(EventInfo eventInfo, BigDecimal ir, BigDecimal unit) {
		// 근사값 EIR 찾기
		// 1.넘겨받은 IR(A)을 기준으로 현재가치(CV)의 합을 구함
		// 2.차이금액 = 현재가치의 합 ? 취득금액
		// 3.차이금액 0 이상이면 increase
		//         0 이하이면 decrease
		// 4.차이금액의 부호가 역전되는 시점의 IR(B)를 찾는다
		// 5.IR(A), IR(B), 차이금액(A), 차이금액(B)를 가지고 Trial and error Method 공식으로 근사값 EIR를 찾아 리턴함
		
		BigDecimal ir_a = ir;
		BigDecimal ir_b = ir;
		BigDecimal diffAmt_a = new BigDecimal("0");
		BigDecimal diffAmt_b = new BigDecimal("0");
		
		BigDecimal sumCv_a = new BigDecimal("0");
		for(int i=1; i<eventInfo.cfList.size(); i++) {
			// 현재가치 및 현재가치의 합 구함
			BigDecimal a = strToDecimal("1").add(ir_a);
			BigDecimal b = intToDecimal(eventInfo.cfList.get(i).addDays)
								.divide(strToDecimal("365"), 10, BigDecimal.ROUND_DOWN);
			double powAb = Math.pow(a.doubleValue(), b.doubleValue());
			
			BigDecimal cv = strToDecimal(eventInfo.cfList.get(i).totalAmt)
								.divide(strToDecimal(Double.toString(powAb)), 2, BigDecimal.ROUND_DOWN);
			sumCv_a = sumCv_a.add(cv);
		}
		// 차이금액(A) = 현재가치의 합 ? 취득금액
		diffAmt_a = sumCv_a.subtract(strToDecimal(eventInfo.evetAmt));
		int diffAmtSign = diffAmt_a.compareTo(strToDecimal("0"));
		
		for(int i=0; i<10; i++) {
			BigDecimal sumCv_b = new BigDecimal("0");
			
			if(diffAmtSign == 1) {
				ir_b = ir_b.add(unit);
			} else {
				ir_b = ir_b.subtract(unit);
			}
			
			for(int j=1; j<eventInfo.cfList.size(); j++) {
				// 현재가치 및 현재가치의 합 구함
				BigDecimal a = strToDecimal("1").add(ir_b);
				BigDecimal b = intToDecimal(eventInfo.cfList.get(j).addDays)
									.divide(strToDecimal("365"), 10, BigDecimal.ROUND_DOWN);
				double powAb = Math.pow(a.doubleValue(), b.doubleValue());

				BigDecimal cv = strToDecimal(eventInfo.cfList.get(j).totalAmt)
									.divide(strToDecimal(Double.toString(powAb)), 2, BigDecimal.ROUND_DOWN);
				sumCv_b = sumCv_b.add(cv);
			}
			// 차이금액(B) = 현재가치의 합 ? 취득금액
			diffAmt_b = sumCv_b.subtract(strToDecimal(eventInfo.evetAmt));
			
			// 차이금액의 부호가 역전되는 시점의 IR(B)를 찾으면 break
			if(diffAmtSign != diffAmt_b.compareTo(strToDecimal("0"))) {
				break;
			}
		}
		
		// IR(A), IR(B)을 가지고 Trial and error Method 공식으로 근사값 계산
		BigDecimal step1 = diffAmt_a.subtract(diffAmt_b);
		BigDecimal step2 = diffAmt_a.divide(step1, 10, BigDecimal.ROUND_DOWN);
		BigDecimal step3 = ir_b.subtract(ir_a);
		return step3.multiply(step2).add(ir_a).setScale(10, BigDecimal.ROUND_DOWN).toString();
	}
	
	
	/**
	 * 상각테이블
	 * @param bondInfo
	 * @param eventInfo
	 */
	public static void calcDepreciationTable(BondInfo bondInfo, EventInfo eventInfo) {
		// 상각테이블
		// 1.상각리스트에 종류별 레코드 삽입(1:매수, 2:이자, 3:결산, 4:만기)
		// 2.생성된 상각리스트 정렬
		// 3.상각일수 계산
		// 4.액면이자 계산
		
		// 레코드 삽입(1.매수)
		DprcInfo dpInfo_1 = new DprcInfo();
		dpInfo_1.cfDate = eventInfo.eventDate;
		dpInfo_1.dprcType = 1;
		eventInfo.dpList.add(dpInfo_1);
		// 레코드 삽입(2:이자)
		String afterIntDate = ""; // 직후 이자 지급일
		Calendar calIssueDate = strDtToCal(bondInfo.issueDate); // 발행일자
		Calendar calEventDate = strDtToCal(eventInfo.eventDate); // 취득일
		while(calEventDate.after(calIssueDate)) {
			calIssueDate.add(Calendar.MONTH, bondInfo.intCycle);
			afterIntDate = calToStrDt(calIssueDate);
		}
		Calendar calAfterIntDate = strDtToCal(afterIntDate); // 취득 후 최초 이자 발생일
		Calendar calExpireDate = strDtToCal(bondInfo.expireDate); // 만기일
		while(calExpireDate.after(calAfterIntDate)) {
			// 취득 후 최초 이자발생일부터 만기일까지 이자지급주기 처리
			DprcInfo dpInfo_2 = new DprcInfo();
			dpInfo_2.cfDate = calToStrDt(calAfterIntDate);
			dpInfo_2.dprcType = 2;
			eventInfo.dpList.add(dpInfo_2);
			
			calAfterIntDate.add(Calendar.MONTH, bondInfo.intCycle);
		}
		// 레코드 삽입(3:결산)
		while(calExpireDate.after(calEventDate)) {
			// 취득일부터 만기일까지 매월 말일 결산처리
			Calendar endMonth = calEventDate;
			int lastDay = endMonth.getActualMaximum(Calendar.DAY_OF_MONTH);
			endMonth.set(Calendar.DAY_OF_MONTH, lastDay);

			DprcInfo dpInfo_3 = new DprcInfo();
			dpInfo_3.cfDate = calToStrDt(endMonth);
			dpInfo_3.dprcType = 3;
			eventInfo.dpList.add(dpInfo_3);
			
			calEventDate.add(Calendar.MONTH, 1);
		}
		// 레코드 삽입(4:만기)
		DprcInfo dpInfo_4 = new DprcInfo();
		dpInfo_4.cfDate = bondInfo.expireDate;
		dpInfo_4.dprcType = 4;
		eventInfo.dpList.add(dpInfo_4);
		
		// 상각리스트 정렬
		Collections.sort(eventInfo.dpList, new DprcSort());
		
		// 상각액상각표 처리로직
		DprcInfo beforeDprc = null;
		DprcInfo _beforeDprc = null;
		for(int i=0; i<eventInfo.dpList.size(); i++) {
			if(beforeDprc == null) {
				// 전상각스케쥴
				beforeDprc = eventInfo.dpList.get(i);
				beforeDprc.faceAmt = bondInfo.faceAmt; // 액면금액
				beforeDprc.closingBookAmt = eventInfo.evetAmt; // 기말장부금액

				_beforeDprc = eventInfo.dpList.get(i);
				_beforeDprc._closingBookAmt = eventInfo.evetAmt; // 기말장부금액
			}
			// 현재상각스케쥴
			DprcInfo currentDprc = eventInfo.dpList.get(i);
			
			// ----------상각액 상각표----------
			// 1)액면금액
			currentDprc.faceAmt = beforeDprc.faceAmt;
			
			// 2)상각일수(현상각스케쥴의 기준일자 ? 전상각스케쥴의 기준일자)
			String from = beforeDprc.cfDate;
			String to = currentDprc.cfDate;
			currentDprc.dprcDays = daysBetween(from, to);
			
			// ----------유효이자 상각표----------
			// 1)_기초상각후원가
			currentDprc._openingBookAmt = beforeDprc._closingBookAmt;
			
			// 2)_유효이자
			strToDecimal(currentDprc._openingBookAmt);
			BigDecimal a = strToDecimal("1").add(strToDecimal(eventInfo.eir));
			BigDecimal b = intToDecimal(currentDprc.dprcDays)
								.divide(strToDecimal("365"), 10, BigDecimal.ROUND_DOWN);
			double powAb = Math.pow(a.doubleValue(), b.doubleValue());
			currentDprc._effectiveInt = strToDecimal(Double.toString(powAb))
											.subtract(strToDecimal("1"))
											.multiply(strToDecimal(currentDprc._openingBookAmt))
											.setScale(2, BigDecimal.ROUND_DOWN)
											.toString();
			
			// 3)_액면이자(발생)
			if(currentDprc.dprcType == 2 || currentDprc.dprcType == 4) {
				BondInfo bond = new BondInfo();
				bond.faceAmt = currentDprc.faceAmt;
				bond.bondType = 2;
				bond.issueDate = _beforeDprc.cfDate;
				bond.intCycle = bondInfo.intCycle;
				bond.ir = bondInfo.ir;
				
				EventInfo event = new EventInfo();
				event.eventDate = currentDprc.cfDate;
				
				currentDprc._faceInt = calAccruedInt(bond, event);
				_beforeDprc = currentDprc;
			}
			
			// 4)_상각액
			currentDprc._dprcAmt = strToDecimal(currentDprc._effectiveInt)
										.subtract(strToDecimal(currentDprc._faceInt))
										.setScale(2, BigDecimal.ROUND_DOWN)
										.toString();
			
			// 5)_기말상각후원가
			currentDprc._closingBookAmt = strToDecimal(currentDprc._openingBookAmt)
											.add(strToDecimal(currentDprc._dprcAmt))
											.setScale(2, BigDecimal.ROUND_DOWN)
											.toString();
			
			// ----------상각액 상각표----------
			// 3)기초상각후원가(전상각스케쥴.기말장부금액)
			currentDprc.openingBookAmt = beforeDprc.closingBookAmt;
			
			// 4)유효이자(유효이자상각표.유효이자 * 액면금액 / 액면금액)
			currentDprc.effectiveInt = strToDecimal(currentDprc._effectiveInt)
											.multiply(strToDecimal(currentDprc.faceAmt))
											.divide(strToDecimal(bondInfo.faceAmt), 2, BigDecimal.ROUND_DOWN)
											.toString();
			
			// 5)액면이자
			BondInfo bond = new BondInfo();
			bond.faceAmt = currentDprc.faceAmt;
			bond.bondType = 2;
			bond.issueDate = beforeDprc.cfDate;
			bond.intCycle = bondInfo.intCycle;
			bond.ir = bondInfo.ir;
			
			EventInfo event = new EventInfo();
			event.eventDate = currentDprc.cfDate;
			
			currentDprc.faceInt = calAccruedInt(bond, event);
			
			// 6)상각액(유효이자 ? 액면이자)
			currentDprc.dprcAmt = strToDecimal(currentDprc.effectiveInt)
										.subtract(strToDecimal(currentDprc.faceInt))
										.setScale(2, BigDecimal.ROUND_DOWN)
										.toString();
			
			// 7)기말상각후원가(기초장부금액 + 상각액)
			currentDprc.closingBookAmt = strToDecimal(currentDprc.openingBookAmt)
											.add(strToDecimal(currentDprc.dprcAmt))
											.setScale(2, BigDecimal.ROUND_DOWN)
											.toString();
			
			// 8)미상각잔액(액면금액 ? 기말장부금액)
			currentDprc.unDprcBal = strToDecimal(currentDprc.faceAmt)
											.subtract(strToDecimal(currentDprc.closingBookAmt))
											.setScale(2, BigDecimal.ROUND_DOWN)
											.toString();
			
			// 계산을 위한 전상각스케쥴 변수로 저장
			beforeDprc = currentDprc;
		}
 	}
	
	
	/**
	 * 금액을 출력하는 함수
	 * @param amt
	 * @param type (1.반올림, 2.올림, 3.절사)
	 * @return
	 */
	public static float printAmt(double amt, int type) {
		float result = 0;
		
		switch(type) {
        case 1:
			// 1.반올림
			result = (float) (Math.round(amt * 100) / 100.0);
        	break;
        case 2:
			// 2.올림
			result = (float) Math.ceil(amt * 100) / 100;
        	break;
        case 3:
			// 3.절사
			result = (float) Math.floor(amt * 100) / 100;
        	break;
		}
		
		return result;
	}
	
	
	public static BigDecimal strToDecimal(String str) {
		return new BigDecimal(str);
	}
	public static BigDecimal intToDecimal(int n) {
		return new BigDecimal(Integer.toString(n));
	}
	
	
	// Calendar to String Date
	public static String calToStrDt(Calendar cal) {
		SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd", Locale.getDefault());
		return sdf.format(cal.getTime());
	}
	
	
	// String Date to Calendar
	public static Calendar strDtToCal(String strDt) {
		Date date = new Date();
		try {
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd", Locale.getDefault());
			date = sdf.parse(strDt);
		} catch (ParseException e) {
			System.out.println("Worker.strDtToCal: ParseException="+e.getMessage());
		}
		Calendar cal = Calendar.getInstance();
		cal.setTime(date);

		return cal;
	}
	
	
	// days between
	public static int daysBetween(String from, String to) {
		int days = 0;
		SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd", Locale.getDefault());
		
		try {
			Date fromDate = sdf.parse(from);
			Date toDate = sdf.parse(to);
			
			days = (int) ((toDate.getTime() - fromDate.getTime()) / (24 * 60 * 60 * 1000));
		} catch (ParseException e) {
			System.out.println("Worker.daysBetween: ParseException="+e.getMessage());
		}
		
		return days;
	}
	
	
	public static class DprcSort implements Comparator<DprcInfo> {
		@Override
		public int compare(DprcInfo dpInfo1, DprcInfo dpInfo2) {
			return dpInfo1.cfDate.compareTo(dpInfo2.cfDate);
		}
	}
}