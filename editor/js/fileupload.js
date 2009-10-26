<!--
function extract(what,where) {
    t = new Date();   timestamp=Math.round(t.getTime()/1000) ;
    if (what.indexOf('/') > -1) {
        answer = what.substring(what.lastIndexOf('/')+1,what.length);   
    }
    else {
        answer = what.substring(what.lastIndexOf('\\')+1,what.length);
    }
    where.value = answer;
}
//-->
