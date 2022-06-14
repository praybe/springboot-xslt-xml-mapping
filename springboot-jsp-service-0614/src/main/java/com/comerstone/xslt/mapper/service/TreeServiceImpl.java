package com.comerstone.xslt.mapper.service;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Service
@AllArgsConstructor
@NoArgsConstructor
@ToString
@Getter
@Setter
public class TreeServiceImpl implements TreeService {
	
	@Override
	public String getName() {
		
		String name = "Xslt";
		
		return name;
		
		
	}

}
