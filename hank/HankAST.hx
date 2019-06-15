package hank;

import haxe.ds.Option;
import hank.Alt.AltInstance;
import hank.Choice.ChoicePointInfo;

enum ExprType {
	EIncludeFile(path:String);

	EOutput(o:Output);
	EDivert(targets:Array<String>);
	EThread(target:String);
	EKnot(name:String);
	EStitch(name:String);
	ENoOp;
	EHaxeLine(haxe:String);
	EHaxeBlock(haxe:String);
	EGather(label:Option<String>, depth:Int, expr:ExprType);
	// Choices are the most complicated expressions
	EChoice(c:Choice);
}

typedef HankExpr = {
	var position:HankBuffer.Position;
	var expr:ExprType;
}

typedef HankAST = Array<HankExpr>;

/**
	Implements helper functions for navigating a Hank AST.
**/
class ASTExtension {
	public static function findFile(ast:HankAST, path:String) {
		for (i in 0...ast.length) {
			var expr = ast[i];
			if (expr.position.file == path) {
				return i;
			}
		}

		return -1;
	}

	public static function findEOF(ast:HankAST, path:String) {
		for (i in 0...ast.length) {
			var expr = ast[ast.length - 1 - i];
			if (expr.position.file == path) {
				return ast.length - 1 - i + 1;
			}
		}

		return -1;
	}

	/**
		Collect every choice in the choice point starting at the given index.
	**/
	public static function collectChoices(ast:HankAST, startingIndex:Int, depth:Int):ChoicePointInfo {
		var choices = [];
		var lastChoiceIndex = 0;
		if (startingIndex > ast.length || startingIndex < 0) {
			throw 'Trying to collect choices starting from expr ${startingIndex + 1}/${ast.length}';
		}
		var currentFile = ast[startingIndex].position.file;

		for (i in startingIndex...findEOF(ast, currentFile)) {
			switch (ast[i].expr) {
				// Gather choices of the current depth
				case EChoice(choice):
					if (choice.depth != depth)
						continue;
					else {
						lastChoiceIndex = i;
						choices.push(choice);
					};
				// Stop at the next gather of this depth
				case EGather(_, d, _) if (d == depth):
					break;
				// Stop at knot or stitch declarations
				case EKnot(_) | EStitch(_):
					break;
				default:
			}
		}

		return {choices: choices, fallbackIndex: lastChoiceIndex};
	}

	public static function findNextGather(ast:HankAST, path:String, startingIndex:Int, maxDepth:Int):Int {
		for (i in startingIndex...findEOF(ast, path)) {
			switch (ast[i].expr) {
				case EGather(_, depth, _) if (depth <= maxDepth):
					return i;
				default:
			}
		}

		return -1;
	}

	public static function indexOfChoice(ast:HankAST, id:Int):Int {
		for (i in 0...ast.length) {
			var expr = ast[i].expr;
			switch (expr) {
				case EChoice(c) if (c.id == id):
					return i;
				default:
			}
		}
		return -1;
	}
}
