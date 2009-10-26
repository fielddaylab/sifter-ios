<?php /* Smarty version 2.6.19, created on 2008-08-12 23:37:20
         compiled from /Applications/MAMP/htdocs/aris/games/aris/Framework/Site/Aris/Framework/Module/Test/Templates/Default/Test.tpl */ ?>
<?php if (strlen ( $this->_tpl_vars['result'] )): ?>
<h3><?php echo $this->_tpl_vars['result']; ?>
</h3>
<?php endif; ?>
<form method="post" action="<?php echo $_SERVER['REQUEST_URI']; ?>
">
What is 2 + 2? <input type="text" size="4" name="answer" /> <input type="submit" value="Score!" />
</form>