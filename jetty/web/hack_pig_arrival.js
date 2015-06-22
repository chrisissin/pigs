
function pigGenerator(ofsettop) {
	YUI().use('node', function (Y) {
		var new_pig = Y.one('.rocketpig').cloneNode(true);	
			new_pig._node.style.position = 'absolute';
		
		new_pig._node.style.display = '';
		new_pig._node.style.top = ofsettop + 'px';
		new_pig.addClass('inside_the_farm');
		Y.one('.farm').insert(new_pig);		
	});
}

YUI().use('node', 'event', 'node-event-simulate', 'io', function (Y) {
	setInterval(function(){
		
		Y.io('/api/pig?action=arrival', {
			method: 'GET',
			on: {
				success: function (id, result) {
					var offset = result.responseText;
					if( offset > 0 ) {
						pigGenerator(result.responseText);
					}
				},
				failure: function (id, result) {
				}
			}
		});
//		
//		Y.all('.rocketpig.inside_the_farm').each( function() {
//			var offsetLeft = this._node.offsetLeft + (Math.random() * 150),
//				offsetTop = this._node.offsetTop;
//			if (offsetLeft <= 300) {
//				this.setStyle('left', (offsetLeft) + 'px');
//			} else {
//				this.addClass('out_of_farm');
//				this.setStyle('display','none');
//			}
//		})
	}, 300);
	
	setInterval(function(){
		Y.all('.rocketpig.inside_the_farm').each( function() {
			var offsetLeft = this._node.offsetLeft + (Math.random() * 10),
				offsetTop = this._node.offsetTop;
			if (offsetLeft <= 300) {
				this.setStyle('left', (offsetLeft) + 'px');
			} else {
				this.addClass('out_of_farm');
				this.setStyle('display','none');
			}
		})
	}, 50);
});
//
//var offsettop = 0;
//
//for(var i=0;i<=7;i++) {
//	offsettop = i*30;
//	pigGenerator(offsettop);
//}

