<?php
/*=========================================================================

  Program:   CDash - Cross-Platform Dashboard System
  Module:    $RCSfile: common.php,v $
  Language:  PHP
  Date:      $Date$
  Version:   $Revision$

  Copyright (c) 2002 Kitware, Inc.  All rights reserved.
  See Copyright.txt or http://www.cmake.org/HTML/Copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even 
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
     PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
include("config.php");
include("common.php");

@$buildid = $_GET["buildid"];
@$date = $_GET["date"];

include("config.php");
$db = mysql_connect("$CDASH_DB_HOST", "$CDASH_DB_LOGIN","$CDASH_DB_PASS");
mysql_select_db("$CDASH_DB_NAME",$db);
		
$build_array = mysql_fetch_array(mysql_query("SELECT * FROM build WHERE id='$buildid'"));		
$projectid = $build_array["projectid"];
$date = date("Ymd", strtotime($build_array["starttime"]));

$project = mysql_query("SELECT * FROM project WHERE id='$projectid'");
if(mysql_num_rows($project)>0)
		{
		$project_array = mysql_fetch_array($project);
		$svnurl = $project_array["cvsurl"];
		$homeurl = $project_array["homeurl"];
		$bugurl = $project_array["bugtrackerurl"];			
		$projectname	= $project_array["name"];		
		}

list ($previousdate, $currenttime, $nextdate) = get_dates($date);
$logoid = getLogoID($projectid);

$xml = '<?xml version="1.0"?><cdash>';
$xml .= "<title>CDash : ".$projectname."</title>";
$xml .= "<cssfile>".$CDASH_CSS_FILE."</cssfile>";
$xml .="<dashboard>
  <datetime>".date("D, d M Y H:i:s",strtotime($build_array["starttime"]))."</datetime>
  <date>".$date."</date>
  <svn>".$svnurl."</svn>
  <bugtracker>".$bugurl."</bugtracker>	
  <home>".$homeurl."</home>
  <projectid>".$projectid."</projectid>	
  <logoid>".$logoid."</logoid>
  <projectname>".$projectname."</projectname>	
  <previousdate>".$previousdate."</previousdate>	
  <nextdate>".$nextdate."</nextdate>	
  </dashboard>
  ";
		
		// Build
		$xml .= "<build>";
		$build = mysql_query("SELECT * FROM build WHERE id='$buildid'");
		$build_array = mysql_fetch_array($build); 
		$siteid = $build_array["siteid"];
		$site_array = mysql_fetch_array(mysql_query("SELECT name FROM site WHERE id='$siteid'"));
		$xml .= add_XML_value("site",$site_array["name"]);
		$xml .= add_XML_value("buildname",$build_array["name"]);
		$xml .= add_XML_value("buildid",$build_array["id"]);
  $xml .= "</build>";
		
		@$type = $_GET["type"];
		if(!isset($type))
		  {
				$type = 0;
		  }
		// Set the error
		if($type == 0)
		  {
				$xml .= add_XML_value("errortypename","Error");
				$xml .= add_XML_value("nonerrortypename","Warning");
				$xml .= add_XML_value("nonerrortype","1");	
		  }
		else
				{
				$xml .= add_XML_value("errortypename","Warning");
				$xml .= add_XML_value("nonerrortypename","Error");
				$xml .= add_XML_value("nonerrortype","0");	
				} 
		
		$xml .= "<errors>";
		
	 $errors = mysql_query("SELECT * FROM builderror WHERE buildid='$buildid' and type='$type'");
		while($error_array = mysql_fetch_array($errors))
		  {
				$xml .= "<error>";
				$xml .= add_XML_value("logline",htmlspecialchars($error_array["logline"]));
				$xml .= add_XML_value("text",htmlspecialchars($error_array["text"]));
				$xml .= add_XML_value("sourcefile",$error_array["sourcefile"]);
				$xml .= add_XML_value("sourceline",$error_array["sourceline"]);
				$xml .= add_XML_value("precontext",htmlspecialchars($error_array["precontext"]));
				$xml .= add_XML_value("postcontext",htmlspecialchars($error_array["postcontext"]));
				$xml .= "</error>";
		  }

		$xml .= "</errors>";
  $xml .= "</cdash>";

// Now doing the xslt transition
generate_XSLT($xml,"viewBuildError");
?>
