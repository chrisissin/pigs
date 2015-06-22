YUI().use('node', 'event', 'node-event-simulate', 'io' , function (Y) {

	var pigGenerator = function (e){
		var new_pig = e.currentTarget.cloneNode(true);	
		
		new_pig._node.style.position = 'absolute';
		new_pig._node.style.display = '';
		new_pig._node.style.top = (Math.random() * 450) + 'px';
		//new_pig.setStyle({'position':'absolute', 'display':'', 'top': (Math.random() * 420 + 30) + 'px'});
		new_pig.addClass('inside_the_farm');
		Y.one('.farm').insert(new_pig);
	};

	Y.all('.rocketpig').on('click', pigGenerator);
	
	setInterval(function(){
		Y.all('.rocketpig.inside_the_farm').each( function() {
			var offsetLeft = this._node.offsetLeft + (Math.random() * 150),
				offsetTop = this._node.offsetTop;
			if (offsetLeft <= 300) {
				this.setStyle('left', (offsetLeft) + 'px');
			} else {
				this.addClass('out_of_farm');
				this.setStyle('display','none');
				
//console.log(offsetTop);
				
				Y.io('/api/pig?action=departure', {
    				method: 'get',
    				data: 'y=' +offsetTop ,
    				on: {
        				success: function (id, result) {
        				},
        				failure: function (id, result) {
        				}
    				}
				});
			}
		});
	}, 500);	
});	

var how_many = 7;
function autoGen(times){
	YUI().use('node-event-simulate' , function (Y) {	
		for(var i=1;i<=times;i++) {
			Y.one('.rocketpig').simulate('click');
		}
	});	
}

autoGen(how_many);

