function pigGenerator(ofsettop) {
	YUI().use('node', function (Y) {
		var new_pig = Y.one('.rocketpig').cloneNode(true);	
			new_pig._node.style.position = 'absolute';
		
		new_pig._node.style.display = '';
		new_pig._node.style.top = (Math.random() * 450) + 'px';
		new_pig.addClass('inside_the_farm');
		Y.one('.farm').insert(new_pig);		
	});
}

YUI().use('node', function (Y) {
	setInterval(function(){
		Y.all('.rocketpig.inside_the_farm').each( function() {
			var offsetLeft = this._node.offsetLeft + (Math.random() * 150),
				offsetTop = this._node.offsetTop;
			if (offsetLeft <= 300) {
				this.setStyle('left', (offsetLeft) + 'px');
			} else {
				this.addClass('out_of_farm');
				this.setStyle('display','none');
			}
		})
	}, 500);
});

var offsettop = 0;

for(var i=0;i<=7;i++) {
	offsettop = i*30;
	pigGenerator(offsettop);
}

