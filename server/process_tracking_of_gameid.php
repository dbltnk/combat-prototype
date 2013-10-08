<?php

$mysqli = new mysqli("localhost", "dastal", "", "dastal");

$sid = $argv[1];
$gameid = $argv[2];

$where = "session = " . intval($sid) . " and gameid = " . intval($gameid);

function selectOnes($query) {
	global $mysqli;
	$r = array();

	$q = $mysqli->query($query);
	while($row = $q->fetch_array()){
		$r[] = $row[0];
	}
	
	return $r;
}

function selectOne($query) {
	$r = selectOnes($query);
	return $r[0];
}

// skill
$skills_used = selectOnes("SELECT DISTINCT p2 FROM raw WHERE event = 'skill_used' AND $where ORDER BY p2");

foreach($skills_used as $skill) {
	$used = selectOne("select count(*) from raw where event = 'skill_used' and $where and p2 = '$skill'");
	$miss = selectOne("select count(*) from raw where event = 'skill_miss' and $where and p2 = '$skill'");
	$hit = selectOne("select count(*) from raw where event = 'skill_hit' and $where and p2 = '$skill'");
	print("skill $skill used $used missed $miss hit $hit - " . round($hit / $used * 100,2) . "%");
	print("\n");
}

