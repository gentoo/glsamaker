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

$ID='<novalue>';
foreach($HTTP_GET_VARS as $key => $value) 
	{ if($key == 'id' || $key == 'glsa') $ID = $value; }

if(sscanf($ID, '%04d%02d-%d', $ID1, $ID2, $ID3) == 3){ $valid = true; }
if(preg_match('/^[A-F0-9]{32}$/i', $ID)){ $valid = true; $pool = true; }

if($ID == '<novalue>'){ echo 'No GLSA ID has been specified.'; die(); }
else if ( $valid == false ) { echo 'Invalid GLSA ID [` ', $ID, ' `] specified!'; die(); }

header('Content-Disposition: attachment; filename="glsa-'.$ID.'.xml"');
echo fileGrepper_getGLSAText( $pool ? NULL: $ID1, $pool ? NULL: $ID2, $pool ? NULL: $ID3, $pool ? $ID : NULL);

?>
