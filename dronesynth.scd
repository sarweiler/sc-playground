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

~initGrid = {
	~gridPitchValues.do({ | xpos, row |
		~m.levrow(0,row,[8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
	})
};

~initGrid.value;

~gridSetPitch = { | row, xpos |
	var fillRowBefore;
	var fillRowAfter;
	var toFill;
	var setRow;
	fillRowBefore = Array.fill(xpos, 2);
	toFill = 15 - fillRowBefore.size;
	fillRowAfter = Array.fill(toFill, 0);
	setRow = fillRowBefore ++ Array.with(8) ++ fillRowAfter;
	~m.levrow(0,row,setRow);
	~gridPitchValues[row] = xpos;
};

OSCFunc.newMatching({ | message, time, addr, recvPort |
	var gridX = message[1];
	var gridY = message[2];
	var buttonDown = message[3];

	~gridSetPitch.value(gridY, gridX);

	message.postln;
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
	~m.levset(xpos,row, 12);
	SystemClock.sched(0.1, {
		~m.levset(xpos,row, 8);
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
