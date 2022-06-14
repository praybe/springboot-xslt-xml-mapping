package com.comerstone.xslt.mapper.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.comerstone.xslt.mapper.service.TreeService;

@Controller
public class HomeController {
	
	@Autowired
	TreeService treeService;
	
	@GetMapping("/home")
	public String treeHome(Model model) {
		
		model.addAttribute("test2", treeService.getName());
		
		return "home";
	}

}
