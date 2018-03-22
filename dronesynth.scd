s.boot
s.scope

//
// INITIALIZE GRID
//
(
~m = MonoM.new("/monome", 0);
~m.useDevice(0);
~m.darkness;

~gridPitchValues = [0,0,0,0,0,0,0,0];
~gridOctaveValues = [0,0,3,0,0,0,0,0];
~gridRowInEditMode = [0,0,0,0,0,0,0,0]; // TODO: Boolean

~keysHeld = 0;

~initGrid = {
	~gridPitchValues.do({ | xpos, row |
		~m.levrow(0,row,[8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	})
};

~initGrid.value;

~gridSetPitch = { | row, xpos |
	~gridDisplayRow.value(row);
	~gridPitchValues[row] = xpos;
	// set pitch values
};

~gridSetOctave = { | row, octave |
	if(~gridRowInEditMode[row] == 1,
		{
			if(octave > 5, {
				octave = 5;
			});
			~gridOctaveValues[row] = octave;
			~gridDisplayEditRow.value(row);
			// set octave value
		}
	)
};

~gridDisplayRow = { | row |
	var fillRowBefore;
	var fillRowAfter;
	var toFill;
	var setRow;

	fillRowBefore = Array.fill(~gridPitchValues[row], 2);
	toFill = 15 - fillRowBefore.size;
	fillRowAfter = Array.fill(toFill, 0);
	setRow = fillRowBefore ++ Array.with(8) ++ fillRowAfter;
	~m.levrow(0,row,setRow);
};

~gridDisplayEditRow = { | row |
	var fillActiveOctave, fillOctaveAfter, setRow;

	fillActiveOctave = Array.fill(~gridOctaveValues[row], 10);
	fillOctaveAfter = Array.fill(15 - fillActiveOctave.size, 4);
	setRow = fillActiveOctave ++ fillOctaveAfter ++ Array.with(0);
	~m.levrow(0,row,setRow);
};




OSCFunc.newMatching({ | message, time, addr, recvPort |
	var gridX = message[1];
	var gridY = message[2];
	var buttonDown = message[3];

	if(buttonDown == 1,
		{ ~keysHeld = ~keysHeld + 1; },
		{ ~keysHeld = ~keysHeld - 1; });

	if((gridX < 15 && (~keysHeld == 1) && (buttonDown == 1)),
		{ ~gridSetPitch.value(gridY, gridX); },
		{
			// TODO: Check if edit mode active, not if 2 buttons held => Array.collect?
			if((buttonDown == 1) && (~keysHeld == 1),
				{
					~gridRowInEditMode[gridY] = 1;
					~gridDisplayEditRow.value(gridY);
				},
				{
					if(~keysHeld == 0, {
						~gridRowInEditMode[gridY] = 0;
						~gridDisplayRow.value(gridY);
					});

				}
			);

			if((~keysHeld == 2) && (~gridRowInEditMode[gridY] == 1),
				{ ~gridSetOctave.value(gridY, gridX + 1); }
			);
		}
	);

	message.postln;
	~keysHeld.postln;
	//~m.ledset(message[1], message[2], message[3]);
	//~m.levset(message[1] - 1, message[2], 6);

}, "/monome/grid/key");
)


//
// INITIALIZE SYNTHDEF
//
(
SynthDef.new(\sineosc, { arg freq = 440, out = 0, dust_freq = 1, device = 0;
	var dust = Dust.kr(dust_freq);
	var env = Env([0.000001, 1, 0.000001], [0.01, 0.09], \exp).kr(0, dust);
	Out.ar(out, FreeVerb2.ar(SinOsc.ar(freq, 0, 0.2) * env, SinOsc.ar(freq, 0, 0.2) * env), \mix, 0.7);
	SendTrig.kr(dust, device);
}).add;
)

//
// INITIALIZE SYNTHS
//
(
~snths = [
	Synth(\sineosc, [\out, 0, \device, 0]),
	Synth(\sineosc, [\out, 1, \device, 1]),
	Synth(\sineosc, [\out, 0, \device, 2]),
	Synth(\sineosc, [\out, 1, \device, 3]),
	Synth(\sineosc, [\out, 0, \device, 4]),
	Synth(\sineosc, [\out, 1, \device, 5]),
	Synth(\sineosc, [\out, 0, \device, 6]),
	Synth(\sineosc, [\out, 1, \device, 7])
];

// visual feedback
OSCFunc.newMatching({ | message, time |
	var row = message[2];
	var xpos = ~gridPitchValues[row];
	if(~gridRowInEditMode[row] == 0, {
		~m.levset(xpos,row, 12);
		SystemClock.sched(0.1, {
			~m.levset(xpos,row, 8);
		});
	});
}, "/tr", s.addr);
)


~m.ledall(0);
~m.levrow(0,2,[2,2,2,2,2,2,8]);
~m.levrow(0, 2, [ 8, 8, 15, 2, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 ]);


//
//
// legacy midi stuff
//
//

MIDIClient.init;
MIDIIn.connectAll;

(
MIDIFunc.cc({ |val, deviceNum, chan, src|
	if((deviceNum >= 0) && (deviceNum <= 7), {
		"FADE".postln;
		"val: " + val.postln;
		"num: " + deviceNum.postln;
		"chan: " + chan.postln;
		"src: " + src.postln;
		"-----".postln;

		~snths[deviceNum].set(
			\dust_freq, val / 8
		);
	})
});

MIDIFunc.cc({ |val, deviceNum, chan, src|
	if((deviceNum >= 16) && (deviceNum <= 23), {
		deviceNum = deviceNum - 16;
		"KNOB".postln;
		"val: " + val.postln;
		"num: " + deviceNum.postln;
		"chan: " + chan.postln;
		"src: " + src.postln;
		"-----".postln;

		~snths[deviceNum].set(
			\freq, val * 8
		);
	});
});
)
