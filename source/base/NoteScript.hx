package base;

import sys.FileSystem;

class NoteScript extends ScriptHandler
{
	public var type:String;

	@:isVar @:noPrivateAccess var skin(get, default):String;

	public function new(type:String)
	{
		this.type = type;

		var scriptFile:String = Paths.getModPath('notetypes', '${type}', 'hx');
		if (!FileSystem.exists(scriptFile))
			scriptFile = Paths.getPreloadPath('notetypes/${type}.hx');
		if (!FileSystem.exists(scriptFile))
		{
			active = false;
			return;
		}

		super(scriptFile, true, false); // do not execute on start
		execute();
		call('create', []);
	}

	override function preset():Void
	{
		set('type', type);
		set('reloadNote', function(tex:String)
		{
			this.skin = tex;

			@:privateAccess
			for (i in states.PlayState.contents.unspawnNotes)
			{
				funkin.Note.reloadPrefixes(tex, '${type}', false, 'base', i);
			}
		});

		super.preset();
	}

	function get_skin():String
		return skin;
}