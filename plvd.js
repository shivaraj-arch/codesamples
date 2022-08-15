var ddlArray = new Array();
var ddl = document.getElementById('ddlDist')
for (i = 0; i < ddl.length; i++) {
  ddlArray[i] = ddl.options[i].text;
}
return ddlArray;

