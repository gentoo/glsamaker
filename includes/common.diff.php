<?

/***************************************************************************
 *                                                                         *
 *   Copyright (C) 2004 Tim Yamin < plasmaroo >                            *
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

function diffStringToFile($string, $file)
{
	$process = proc_open("diff -u - common.version", array(0 => array("pipe", "r"), 1 => array("pipe", "w")), $pipes);
	if (is_resource($process))
	{
		fwrite($pipes[0], "Test!");
		fclose($pipes[0]);

		while (!feof($pipes[1])) {
			$outputString .= fgets($pipes[1], 1024);
		}
		fclose($pipes[1]);
		if(proc_close($process) > 2)
			echo("<b>Error from includes.Diff inside [[ ".__FUNCTION__."//".__LINE__." ]]: Received erroneous code!</b>");
	}
	else
		echo("<b>Error from includes.Diff inside [[ ".__FUNCTION__."//".__LINE__." ]]: Failed to spawn resource!</b>");

	highlight_string($outputString);
}
phpinfo();

// Local Variables: ***
// truncate-lines:true ***
// End: ***

?>
