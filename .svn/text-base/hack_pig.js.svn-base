YUI().use('node', 'event' , function (Y) {

	Y.all('.rocketpig').on('click', function(e) { 
		var new_pig = e.currentTarget.cloneNode(true);	
		new_pig._node.style.position = 'absolute';
		new_pig._node.style.top = Math.random() * 800 + 'px';
		new_pig._node.style.left = Math.random() * 300 + 'px';
		new_pig.addClass('inside_the_farm');
		Y.one('.farm').insert(new_pig);
	});
	
	setInterval(function(){
		Y.all('.rocketpig.inside_the_farm').each( function() {
			var offsetLeft = this._node.offsetLeft + (Math.random() * 150); //this._node.offsetLeft + 50;
			if (offsetLeft <= 1150) {
				this.setStyle('left', (offsetLeft) + 'px');
			} else {
				this.addClass('out_of_farm');
				this.setStyle('display','none');
			}
		});
	}, 500);
});	


