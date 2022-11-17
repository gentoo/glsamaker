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
	atom.setAttribute('size', 40);
	arch.setAttribute('name', which + '_arch[]');
	remove.setAttribute('type', 'button');
	remove.setAttribute('onclick', 'deleterow(this)');
	remove.innerHTML = '<b>-</b>';
	atomCol.appendChild(atom);
	archCol.appendChild(arch);
	buttonCol.appendChild(remove);
}

function deleterow(t) {
	/* We only want to allow removal if there's more than one to remove.
	 * 2 = one regular row and row heading, only remove if there's
	 * more rows than this
	 */
	if (t.parentElement.parentElement.parentElement.childElementCount > 2) {
		t.parentElement.parentElement.remove();
	}
}
