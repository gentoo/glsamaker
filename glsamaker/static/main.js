function newrow(which) {
	var tbl = document.getElementById(which);
	var row = tbl.insertRow();
	var atomCol = row.insertCell(0);
	var archCol = row.insertCell(1);
	var buttonCol = row.insertCell(2);
	var atom = document.createElement('input');
	var arch = document.createElement('input');
	var remove = document.createElement('button');
	atom.setAttribute('name', which + '[]');
	arch.setAttribute('name', which + '_arch[]');
	remove.setAttribute('type', 'button');
	remove.setAttribute('onclick', 'deleterow(this)');
	remove.innerHTML = '<b>-</b>';
	atomCol.appendChild(atom);
	archCol.appendChild(arch);
	buttonCol.appendChild(remove);
}

function deleterow(t) {
	t.parentElement.parentElement.remove();
}
