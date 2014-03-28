package com.test.app;


import java.math.BigDecimal;
import java.util.ArrayList;

import com.test.common.Worker;
import com.test.model.BondInfo;
import com.test.model.CashFlowInfo;
import com.test.model.DprcInfo;
import com.test.model.EventInfo;

public class BondProcess {

	public static void main(String[] args) {
		
        // set 채권정보
        BondInfo bondInfo = new BondInfo();
        bondInfo.faceAmt = "10000000";		// 액면금액
        bondInfo.bondType = 2;				// 금리유형(1.할인채, 2.이표채(단리), 3.단리채(만기), 4.복리채)
        bondInfo.issueDate = "20121120";	// 발행일자
        bondInfo.expireDate = "20131120";	// 만기일자
        bondInfo.ir = "0.108";				// 액면이자율
        bondInfo.intCycle = 6;				// 이자지급주기
        
        // set 매수정보
        EventInfo eventInfo = new EventInfo();
        eventInfo.eventDate = "20130515";		// 취득일
        eventInfo.evetAmt = "9800000";			// 취득금액
        eventInfo.cfList = new ArrayList<CashFlowInfo>();	// CashFlow List
        eventInfo.dpList = new ArrayList<DprcInfo>();	// 상각 List
        
        String accruedInt = "0";
        
        // 1.경과이자계산
        accruedInt = Worker.calAccruedInt(bondInfo, eventInfo);
        System.out.println("BondProcess.main: accruedInt="+accruedInt);
        
        // 2.Cash Flow
        Worker.calCashFlow(bondInfo, eventInfo);
        for(int i=0; i<eventInfo.cfList.size(); i++) {
        	System.out.println("BondProcess.main: "+eventInfo.cfList.get(i).toString());
        }
        
        // 3.EIR
        Worker.calEir(bondInfo, eventInfo);
        eventInfo.eir = Worker.strToDecimal(eventInfo.eir)
        							.setScale(10, BigDecimal.ROUND_DOWN)
        							.toString();
        System.out.println("BondProcess.main: EIR="+eventInfo.eir);
        for(int i=0; i<eventInfo.cfList.size(); i++) {
        	System.out.println("BondProcess.main: "+eventInfo.cfList.get(i).toString());
        }
        
        // 4.상각 테이블
        Worker.calcDepreciationTable(bondInfo, eventInfo);
        for(int i=0; i<eventInfo.dpList.size(); i++) {
        	System.out.println("BondProcess.main: "+eventInfo.dpList.get(i).toString());
        }
	}

}
