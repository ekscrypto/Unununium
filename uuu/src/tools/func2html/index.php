<?
$cell_name_bg = "#303C60";
$cell_name_fg = "#C3C8E2";
$cell_desc_bg1 = "#101420";
$cell_desc_bg2 = "#202840";
$font_face = "Arial";
$font_size = 2;

$status = 0;

function startCell( $cell_name )
{
  global $cell_name_bg, $cell_name_fg, $font_face, $font_size;
  global $cell_desc_bg1, $status;

  echo "<table width=\"80%\" cellpadding=\"0\" cellspacing=\"1\"><tr bgcolor=\"$cell_name_bg\"><td colspan=\"4\"><font face=\"$font_face\" size=\"$font_size\" color=\"$cell_name_fg\">$cell_name</font></td></tr>\n";
  echo "<tr bgcolor=\"$cell_desc_bg1\"><td>function name</td><td>function class</td><td>function id</td><td>class id</td></tr>\n";

  $status = 0;

}

function providedFunction( $function_name, $function_class, $fid, $cid )
{
  global $cell_desc_bg1, $cell_desc_bg2, $font_face, $font_size;
  global $status;

  if( $status != 1 )
  {
    echo "<tr bgcolor=\"$cell_desc_bg2\"><td colspan=\"4\"><font face=\"$font_face\" size=\"$font_size\"><center>Provided functions</center></font></td></tr>\n";
    $status = 1;
  }

  echo "<tr bgcolor=\"$cell_desc_bg1\"><td width=\"25%\"><font face=\"$font_face\" size=\"$font_size\">$function_name</font></td><td width=\"25%\"><font face=\"$font_face\" size=\"$font_size\">$function_class</font></td><td width=\"25%\"><font face=\"$font_face\" size=\"$font_size\">$fid</font></td><td width=\"25%\"><font face=\"$font_face\" size=\"$font_size\">$cid</font></td></tr>\n";
}

function requiredFunction( $function_name, $function_class, $fid, $cid)
{
  global $cell_desc_bg1, $cell_desc_bg2, $font_face, $font_size;
  global $status;

  if( $status != 2 )
  {
    echo "<tr bgcolor=\"$cell_desc_bg2\"><td colspan=\"4\"><font face=\"$font_face\" size=\"$font_size\"><center>Required functions</center></font></td></tr>\n";
    $status = 2;
  }

  echo "<tr bgcolor=\"$cell_desc_bg1\"><td width=\"25%\"><font face=\"$font_face\" size=\"$font_size\">$function_name</font></td><td width=\"25%\"><font face=\"$font_face\" size=\"$font_size\">$function_class</font></td><td width=\"25%\"><font face=\"$font_face\" size=\"$font_size\">$fid</font></td><td width=\"25%\"><font face=\"$font_face\" size=\"$font_size\">$cid</font></td></tr>\n";
}

function endCell()
{
 echo "</table><p>\n";
}

?>
<html>
<body bgcolor="#000000" text="#C0C0C0" link="#6B7193" vlink="#6B7193" alink="#C3C8E2"><table border="0" cellspacing="0" cellpadding="0"><tr><td>
<a href="../"><img src="../viewer_small04.jpg" alt="home" align="left" border="0"></a>
.:&nbsp;<a href="../unununium/">unununium</a>&nbsp;:.
.:&nbsp;<a href="../about_us/">about&nbsp;us</a>&nbsp;:.
.:&nbsp;<a href="../news/">news</a>&nbsp;:.
.:&nbsp;cells&nbsp;:.
.:&nbsp;<a href="../distributions/">distributions</a>&nbsp;:.
.:&nbsp;<a href="../related_projects/">related&nbsp;projects</a>&nbsp;:.
</td></tr></table>
<center>be patient!
<p>
<small>to be completed soon, some people are working on the scripts >:}</small>
<? include( "functions.php" ) ?>
</center>
</body></html>

