<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ page session="false"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/jstree/3.2.1/themes/default/style.min.css" />
<script
	src="https://cdnjs.cloudflare.com/ajax/libs/jquery/1.12.1/jquery.min.js"></script>
<script
	src="https://cdnjs.cloudflare.com/ajax/libs/jstree/3.2.1/jstree.min.js"></script>
<script src="https://goessner.net/download/prj/jsonxml/xml2json.js"></script>
<title>Insert title here</title>

<style>
.grid-layout {
	background-color: steelblue;
	padding: 5px;
	display: grid;
	grid-gap: 5px;
	grid-template-areas: 
		'src_code src_code main main dst_code dst_code'
		'src_tree src_tree main main dst_tree dst_tree'
		;
}

.grid-layout>div, .grid-layout>canvas {
	background-color: aliceblue;
	/*
          padding: 20px;
          text-align: center;
          font-size: 18px;
          */
}

#jstree-dnd .jstree-er {
	background: green;
}

#jstree-dnd .jstree-copy {
	margin: 0 2px 0 0;
}

#jstree-dnd.jstree-default .jstree-er {
	background-position: -4px -68px;
}

textarea {
	width: 100%;
	height: 100%;
	resize: none;
}

path {
	animation: move 0.8s linear;
	animation-fill-mode: forwards;
	stroke: blue;
	stroke-width: 4;
	fill: none;
	stroke-dasharray: 1353px;
	stroke-dashoffset: 1353px;
	z-index: 9999;
}

path:hover:not(.selectedPath) {
	opacity: 0.3;
}

@keyframes move { 100% {
	stroke-dashoffset: 0;
}

}
#svg, #main {
	overflow: visible;
	z-index: 999;
}

.selectedPath {
	z-index: 99999;
	stroke: red;
}
</style>
</head>
<body>

	<h2>Convert XML into ${ test2 }</h2>

	<div class="grid-layout">
		<!-- <div style="grid-area: header">Header</div>  -->
		<div style="grid-area: src_code">
			<textarea id="sourceXml" placeholder="source.xml file"></textarea>
		</div>

		<div style="grid-area: src_tree" id="jstree">
			<ul>
				<li>Root</li>
			</ul>
		</div>

		<div style="grid-area: main;" id="main">
			<svg id="svg"></svg>
		</div>
		<div style="grid-area: dst_code">
			<textarea id="targetXml" placeholder="target.xml file"></textarea>
		</div>

		<div style="grid-area: dst_tree; direction: rtl" id="jstree2">
			<ul>
				<li>Root</li>
			</ul>
		</div>
		<!--  <div style="grid-area: footer" id="footer">Footer</div>  -->
	</div>

	<button id="button">refresh button</button>
	<button id="createXSLT">create XSLT</button>
	<button id="transform">transform</button>
	<br> XSLT
	<textarea id="XSLT"></textarea>
	Result XML
	<textarea id="resultXML"></textarea>
	<script>
      class Mapping {
          constructor(fromId, toId) {
            this.fromId = fromId;
            this.toId = toId;
          }
        }
      let mappingArray = [];

      $(function () {
        $.jstree.plugins.myplugin = function (options, parent) {

          // Blocks DND on an other tree than the original one
          this.check = function (chk, obj, par, pos, more) {
              if(parent.check.call(this, chk, obj, par, pos, more) === false) {
                return false;
              }
              if (more && more.dnd && more.is_multi) {
                return false
              }
              return true;
          };
        };
        // 6 create an instance when the DOM is ready
        $('#jstree').jstree({
            "core": {
                "check_callback" : true
            },
            "dnd" : {
                "drop_target" : false
            },
            "plugins": ["dnd", "contextmenu", "myplugin"]
        });
        
        
        $('#jstree2').jstree({
            "core": {
                "check_callback" : true
            },
            "dnd" : {
                "drop_target" : false
            },
            "plugins": ["contextmenu", "myplugin"]
        });
        
        

        $(document).on("dnd_stop.vakata", function (e, data) {
          let target = $(data.event.target);
          if(!target.closest('.jstree').length) {

          } else {
            const start = $(data.element);
            const end = $(data.event.target)
            addMapping(start, end);
          }

        });
        drawPath = (start, end) => {
          const startX = start.offset().left + start.outerWidth();
          const startY = start.offset().top + start.outerHeight() / 2;

          const middleStartX = $('#main').offset().left;
          const middleEndX = $('#main').offset().left + $('#main').outerWidth();

          const endX = end.offset().left;
          const endY = end.offset().top + end.outerHeight() / 2;

          let path = document.createElementNS('http://www.w3.org/2000/svg', "path");

          path.setAttributeNS(null,"d","M" + 0 + "," + 0
                                    + " L" + (middleStartX-startX) + "," + 0
                                    + " L" + ((middleStartX-startX)+(middleEndX-middleStartX)) + "," + (endY-startY)
                                    + " L" + (endX-startX) + "," + (endY-startY)
                                    );

          
          path.setAttributeNS(null, "transform", 'translate(' + -(middleStartX-startX) + ', ' + (startY - $('#svg').offset().top) + ')');
          path.setAttributeNS(null, "from", start.parent().attr("id"));
          path.setAttributeNS(null, "to", end.parent().attr("id"));
          $(path).click(function(e) {
            e.stopPropagation();
            $(this).toggleClass("selectedPath");
          })

          $('#svg').append(path);
        }
        $(document).click((event) => {
            if (!$(event.target).closest("path").length) {
              // the click occured outside paths (clicked elsewhere)
              $(".selectedPath").removeClass("selectedPath");
            }        
        });
        addMapping = (start, end) => {
          drawPath(start, end);

          const mapping = new Mapping(start.parent().attr("id"), end.parent().attr("id"));
          mappingArray.push(mapping);
          
          //mappingArray.forEach((mapping) => {
          //  console.log(mapping.fromId, mapping.toId);
          //})
        }
        $('html').keyup(function(e){
          if(e.keyCode == 46) {
              //alert('Delete key released');
              $('.selectedPath').each(function() {
                const fromId = $(this).attr("from");
                const toId = $(this).attr("to");

                for(let i = 0; i < mappingArray.length; i++)  {
                  if(mappingArray[i].fromId === fromId && mappingArray[i].toId === toId)  {
                    mappingArray.splice(i, 1);
                    this.remove();
                    return;
                  }
                }

              })
          }
        });
        re_render = () => {
          $("#svg").empty();
          mappingArray.forEach((mapping) => {
            let { fromId, toId } = mapping;

            //check parents are open/closed
            while($('#jstree').jstree().get_node(fromId).parent !== '#'
              && $('#jstree').jstree().get_node($('#jstree').jstree().get_node(fromId).parent).state['opened'] === false) {
              fromId = $('#jstree').jstree().get_node(fromId).parent;
            }

            while($('#jstree2').jstree().get_node(toId).parent !== '#'
              && $('#jstree2').jstree().get_node($('#jstree2').jstree().get_node(toId).parent).state['opened'] === false) {
              toId = $('#jstree2').jstree().get_node(toId).parent;
            }

            const fromIdForJQuery = $('#jstree').jstree().get_node(fromId).a_attr.id;
            const toIdForJQuery = $('#jstree2').jstree().get_node(toId).a_attr.id;

            const from = $(document.getElementById(fromIdForJQuery));
            const to = $(document.getElementById(toIdForJQuery))
            //console.log(from.parent().parent().parent());
            drawPath(from, to);
          })
        }

        




        $('#jstree, #jstree2').on("move_node.jstree", function (e, data) {
            console.log(data);
            console.log(data.node.text + " from: " + data.node.id + " to: " + data.parent);
            return false;
        });
        
        // 7 bind to events triggered on the tree
        /* $('#jstree').on("select_node.jstree", function (e, data) {
          if(data.node.data && Object.keys(data.node.data).length !== 0)
            $('#footer').html(data.node.text + ": " + data.node.data); */
            /* else*/
           /* $('#footer').html(data.node.text);*/
        /* }); */

        $('#jstree').on("changed.jstree", function (e, data) {
          console.log(data.action);
        });
        $('#jstree').on("open_node.jstree", function (e, data) {
          console.log(data);
        });
        $('#jstree').on("set_text.jstree", function (e, data) {
          console.log(data);
        });
        $('#jstree').on("rename_node.jstree", function (e, data) {
          console.log(data);
        });
        
        
        
        
        function traverse(tree) {
          if(tree.hasChildNodes()) {
            //document.write('<ul><li>');
            //document.write('<b>'+tree.tagName+' : </b>');
            console.log(tree.tagName);
            for(var i=0; i<tree.childNodes.length; i++)
              traverse(tree.childNodes[i]);
            //document.write('</li></ul>');
          }
          else {
            //leaf node
            //console.log(tree.parentNode.tagName, tree);
            //console.log(tree)
          }
        }

        
        let idNumber = 0;
        let currentTreeIdForFileDrop = "j1_";


        function xml2jsonForJSTree(tree) {
          let json = {};
          
          json['id'] = currentTreeIdForFileDrop + ++idNumber;
          json['text'] = tree.tagName;
          json['state'] = {
              opened: true,
              disabled: false,
              selected: false,
          };
          json['children'] = [];
          //console.log(tree.tagName, tree.data);
          if(tree.hasChildNodes()) {
            for(var i=0; i<tree.childNodes.length; i++) {
              //console.log(tree.childNodes[i].tagName, tree.childNodes[i].data);
              // ???????????? ??? ????????? ????????? ??????
              if(tree.childNodes[i].data && !tree.childNodes[i].data.trim())
                tree.removeChild(tree.childNodes[i]);
              // ????????? ?????? ????????? ????????? ??????
              if(tree.childNodes[i] && !tree.childNodes[i].hasChildNodes() && tree.childNodes[i].data && tree.childNodes[i].data.trim()) {
                json['data'] = tree.childNodes[i].data;
                tree.removeChild(tree.childNodes[i]);
              }

            }
            for(var i=0; i<tree.childNodes.length; i++)
              json['children'][i] = xml2jsonForJSTree(tree.childNodes[i]);
          }
          //Leaf node ??? ????????? ????????? ?????? (???????????? ??????)
          else {
            if(tree.data && tree.data.trim()) {
              json['text'] = 'text()';
              json['data'] = tree.data;
              //console.log(tree);
            }
          }
          return json;
        }
        populateJSTreeWithXML = (selector, xmlText) => {
          var xml = (new DOMParser()).parseFromString(xmlText,'text/xml');
          //traverse(xml.documentElement);
          //let json = JSON.parse(xml2json(xml.documentElement, "\t"));
          idNumber = 0;
          let json = xml2jsonForJSTree(xml.documentElement);
          //console.log(json);

          $(selector).jstree(true).settings.core.data = json;
          $(selector).jstree(true).refresh();
        }
          
        
        
        function dropfile(note, file) {
          var reader = new FileReader();
          reader.onload = function(e) {
            note.value = e.target.result;
          };
          reader.onloadend = function(e) {
            const xmlText = note.value
            if(note.id == "sourceXml")  {
              populateJSTreeWithXML("#jstree", xmlText);
            } else {
              populateJSTreeWithXML("#jstree2", xmlText);
            }
          }
          reader.readAsText(file, "UTF-8");
        }

        sourceXml.ondrop = function(e) {
          e.preventDefault();
          var file = e.dataTransfer.files[0];
          currentTreeIdForFileDrop = "j1_";
          dropfile(this, file);
        };
        targetXml.ondrop = function(e) {
          e.preventDefault();
          var file = e.dataTransfer.files[0];
          currentTreeIdForFileDrop = "j2_";
          dropfile(this, file);
        };



        $('#button').on('click', function () {
          /*
            $('#jstree').jstree(true).select_node('child_node_1');
            $('#jstree').jstree('select_node', 'child_node_1');
            $.jstree.reference('#jstree').select_node('child_node_1');
          */
          //alert("re-rendering");
          re_render();
        });

        iterateJSON = (node) => {
          //do something
          for(let i = 0; i < node.children.length; i++) {
            node.children[i] = iterateJSON(node.children[i]);
          }
          return node;
        }

        transformJSON = (node, depth) => {
          //add depth
          node.depth = depth;

          for(mapping of mappingArray) {
            if(mapping.toId === node.id)  {
              //mark the node
              node.marked = true;

              //add the full path as "node.value"
              const pathArray = $('#jstree').jstree().get_path(mapping.fromId);
              let str = "";
              for(directory of pathArray) {
                str += "/" + directory;
              }
              //remove the first character
              node.value = str.slice(1);
            }
          }

          for(let i = 0; i < node.children.length; i++) {
            node.children[i] = transformJSON(node.children[i], depth + 1);
            if(node.children[i].marked)
              //mark the parents/grandparents of marked node;
              node.marked = true;
          }
          return node;
        }

        removeUnmarkedNodes = (node) => {
          for(let i = 0; i < node.children.length; i++) {
            node.children[i] = removeUnmarkedNodes(node.children[i]);
            if(!node.children[i].marked)  {
              node.children.splice(i, 1);
              i--;
            }
          }
          return node;
        }
        
        toXSLT = (node) => {
          //do something
          let str = "";
          if(node.depth === 0)  {
            str += "<?xml version='1.0' ?>\n";
            str += "<xsl:stylesheet version=\"1.0\" xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\">\n";
            str += "\t<xsl:output omit-xml-declaration=\"yes\" indent=\"yes\"/>"
            str += "\t<xsl:template match=\"/\">\n";
          }
          if(node.marked) {
            for(let i = 0; i < node.depth + 2; i++) {
              str += "\t"
            }
            str += "<" + node.text + ">\n";
          }
          if(node.value)  {
            for(let i = 0; i < node.depth + 3; i++) {
              str += "\t"
            }
            str += "<xsl:value-of select=\"" + node.value + "\"/>\n";

          }
          for(let i = 0; i < node.children.length; i++) {
            str += toXSLT(node.children[i]);
          }
          
          if(node.marked) {
            for(let i = 0; i < node.depth + 2; i++) {
              str += "\t"
            }
            str += "</" + node.text + ">\n";
          }
          if(node.depth === 0)  {
            str += "\t</xsl:template>\n";
            str += "</xsl:stylesheet>";
          }
          return str;
        }
        $('#createXSLT').on('click', function () {
          let json_array = $('#jstree2').jstree().get_json();

          json_array.forEach((node) => {
            node = iterateJSON(node);
            node = transformJSON(node, 0);
            node = removeUnmarkedNodes(node);
            //console.log(node);
            const XSLT = toXSLT(node);
            //console.log(XSLT);
            alert("XSLT copied to clipboard");
            navigator.clipboard.writeText(XSLT);
            $('#XSLT').val(XSLT);
          });
        });

        $('#transform').on('click', function () {
          const xmlText = $('#sourceXml').val();
          const xslText = $('#XSLT').val();

          parser = new DOMParser();
          const xml = parser.parseFromString(xmlText,"text/xml");
          const xsl = parser.parseFromString(xslText,"text/xml");
          //console.log(xml, xsl);
          
          let result;
          //IE
          if (window.ActiveXObject) {
              result = new ActiveXObject("MSXML2.DOMDocument");
              xml.transformNodeToObject(xsl, result);

          // Other browsers
          } else {
              result = new XSLTProcessor();
              result.importStylesheet(xsl);
              result = result.transformToDocument(xml);
          }
          
          result = new XMLSerializer().serializeToString(result);
          $("#resultXML").val(result);
        });

      });


      

      </script>

</body>
</html>