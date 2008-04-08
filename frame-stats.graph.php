<?php

/***************************************************************************
 *                                                                         *
 *   Copyright (C) 2003 Tim Yamin < plasmaroo >                            *
 *               < plasmaroo@plasmaroo.squirrelserver.co.uk >              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 *                                                                         *
 ***************************************************************************/

require_once './includes/io.filegrepper';
require_once './includes/xml.glsaparser';

#require_once './includes/jpgraph/jpgraph.php';
#require_once './includes/jpgraph/jpgraph_bar.php';
#require_once './includes/jpgraph/jpgraph_line.php';
#require_once './includes/jpgraph/jpgraph_regstat.php';
#
require_once 'jpgraph/jpgraph.php';
require_once 'jpgraph/jpgraph_bar.php';
#require_once './includes/jpgraph/jpgraph_bar.php';
require_once 'jpgraph/jpgraph_line.php';
require_once 'jpgraph/jpgraph_regstat.php';

$GetYear == '';
$noPooled == false;

is_numeric($HTTP_GET_VARS['year']) ? $GetYear = $HTTP_GET_VARS['year'] : false;
is_numeric($GetYear) ? $Year = $GetYear : $Year = date('Y');

isset($HTTP_GET_VARS['noPooled']) && $noPooled = true;

$Days  = 365+date('L', mktime(0,0,0,1,1,$Year));
$XRoot = sqrt($Days)*1.48;
$YRoot = sqrt($Days);

clearstatcache();
$GLSAItems = fileGrepper_parseTree(true, true);
$GLSAPools = fileGrepper_parsePool(true);

$LineData = array_fill(0, $Days, '-');
$LineOvrd = $LineData;
$LineURI  = $LineData;
$LineALT  = $LineData;

$i = 1;
foreach ($GLSAItems as $GLSAItem)
{
	sscanf($GLSAItem[0], '%04d%02d-%d', $ID1, $ID2, $ID3);

	$Parser = new GLSAParser();
	$output = fileGrepper_getGLSAText($ID1, $ID2, $ID3);

	if($output != '<nodata>')
	{
		$Parser->GLSAparse($output, true);
		if(($date = strtotime($Parser->GLSADate)) >= mktime(0,0,0,1,1,$Year) && $date <= mktime(0,0,0,1,1,$Year+1))
		{
			$GLSAs[date('n', $date)][] = $date;
			$MDate = date('m', $date)*$XRoot+((date('j', $date)-1)/date('t', $date))*$XRoot;
			if($LineOvrs[$MDate] != '')
			{
				$LineOvrd[$MDate] = $LineOvrs[$MDate];
				$LineALT[$MDate] .= ', '.padNumber($ID1).padNumber($ID2).'-'.padNumber($ID3);
			}
			else
			{
				$LineData[$MDate] = $i;
				$LineOvrs[$MDate] = $i;
				$LineALT[$MDate]  = 'GLSA '.padNumber($ID1).padNumber($ID2).'-'.padNumber($ID3);
				$LineURI[$MDate] = 'frame-view.php?id='.padNumber($ID1).padNumber($ID2).'-'.padNumber($ID3);
			}
			$i++;
		}
	}
}

// Set counter
$GLSAReleased = $i - 1;

if(!$noPooled)
{
	foreach ($GLSAPools as $GLSAPool)
	{
		$Parser = new GLSAParser();
		$output = fileGrepper_getGLSAText(NULL, NULL, NULL, $GLSAPool[0]);

		if($output != '<nodata>')
		{
			$Parser->GLSAparse($output, true);
			if(($date = strtotime($Parser->GLSADate)) >= mktime(0,0,0,1,1,$Year) && $date <= mktime(0,0,0,1,1,$Year+1))
			{
				$PGLSAs[date('n', $date)][] = $date;
				$i++;
			}
		}
	}
}

for ($i = 1; $i <= 12; $i++)
{
	$XYPlot[]  = ($XRoot*$i);
	$XXPlot[]  = count($GLSAs[$i]);
	$XXPlot2[] = count($PGLSAs[$i]);
}

$i = 1;
$peak = max($XXPlot);

function xLabelFormat($input)
{
	global $i, $XYPlot;

	if($input == 0 || $i > 12) return '';
	return date('M', mktime(0,0,0,$i++,1,$Year));
}

function cPointFormat($yVal)
{
	global $LineOvrd;
	if($LineOvrd[array_search($yVal, $LineOvrd)] != '-')
		return array('', 'red', 'red');

	return array('', '', '');
}

// Create the graph. 
$graph = new Graph(550,325);
$graph->SetMarginColor('white');

$graph->SetScale('int',0,0,0,$Days);
$graph->SetY2Scale('int');

// Adjust the margin slightly so that we use the 
// entire area (since we don't use a frame)
$graph->SetMargin(40,40,30,80);

// Box around plotarea
$graph->SetBox(); 

// No frame around the image
$graph->SetFrame(false);

// Setup the tab title
$graph->title->Set('GLSA Release Statistics for '.$Year);

// Setup the X and Y grid
$graph->ygrid->Show(false, false);
$graph->y2grid->SetFill(true,'#DDDDDD@0.5','#BBBBBB@0.5');
$graph->y2grid->SetLineStyle('dashed');
$graph->y2grid->SetColor('gray');
$graph->y2grid->Show();
$graph->xgrid->Show();
$graph->xgrid->SetLineStyle('dashed');
$graph->xgrid->SetColor('gray');

// Set tick marks
$graph->xaxis->scale->ticks->Set($XRoot, $XRoot);
$graph->yaxis->scale->ticks->Set($YRoot, $YRoot);
$graph->yaxis->scale->SetGrace(15,0);
$graph->y2axis->scale->SetGrace(15,0);
$graph->y2axis->SetPos('max');

// Set tick marks to the exterior
$graph->xaxis->SetTickSide(SIDE_BOTTOM);
$graph->yaxis->SetTickSide(SIDE_LEFT);
$graph->y2axis->SetTitle('GLSAs per month', 'middle');
$graph->y2axis->SetTitleSide(SIDE_RIGHT);

// Setup month labels on the X-axis
$graph->xaxis->SetLabelFormatCallback('xLabelFormat');

// Create a bar plot
$bplot = new BarPlot($XXPlot, $XYPlot);
$bplot->SetFillColor('skyblue@0.5');
$bplot->SetWidth(20);

// Create a bar plot
$bplot2 = new BarPlot($XXPlot2, $XYPlot);
$bplot2->SetFillColor('yellow@0.8');
$bplot2->SetWidth(20);

// Setup values
$bplot->value->Show();
$bplot->value->SetFormat('%d');
$bplot->value->SetFont(FF_FONT1,FS_BOLD);
$bplot->SetValuePos('top'); 
$bplot->SetShadow('gray@0.25', 3, 3);

// Line plot
$lplot = new LinePlot($LineData);
$lplot->SetColor('#888888');

$lplot->mark->SetType(MARK_STAR);
$lplot->mark->SetColor('blue@0.5');
$lplot->mark->SetFillColor('lightblue');
$lplot->mark->SetSize(1);
$lplot->mark->SetCallback('cPointFormat');

// Create the red legend
$rplot = new LinePlot($__TempVar__ = array(0 => '-'));
$rplot->SetStyle('dotted');

$rplot->mark->SetType(MARK_STAR);
$rplot->mark->SetColor('red@0.5');
$rplot->mark->SetFillColor('red');
$rplot->mark->SetSize(6);
$rplot->mark->SetCallback('cPointFormat');

// Add Hotspots
$lplot->SetCSIMTargets(&$LineURI, &$LineALT);

// Add Legend
$bplot->SetLegend('GLSAs per month');
$bplot2->SetLegend('Pooled GLSAs');
$bplot2->legendColor = '#c6e3bc';
$lplot->SetLegend('GLSA');
$rplot->SetLegend('Multiple GLSAs');

$graph->legend->SetLayout(LEGEND_HOR);
$graph->legend->Pos(0.5,0.925, 'center', 'bottom');
$graph->footer->center->Set('Total: '.$GLSAReleased.' released GLSAs...');

$graph->AddY2($bplot);
if(!$noPooled)
	$graph->AddY2($bplot2);
$graph->Add($lplot);
$graph->Add($rplot);

// .. and finally send it back to the browser

$graph->img->SetTransparent('white');
if($GetMap)
{
	$ih = $graph->Stroke(_CSIM_SPECIALFILE); 
	$ImageMap = $graph->GetHTMLImageMap('GraphMap');
}
else
	$graph->Stroke();

?>
<?
   // Local Variables: ***
   // truncate-lines:true ***
   // End: ***
?>
