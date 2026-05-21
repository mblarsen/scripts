import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { existsSync, realpathSync } from "node:fs";
import { dirname, join } from "node:path";
import { spawn } from "node:child_process";
import { pathToFileURL } from "node:url";

const COMMAND_NAME = "fux";

function getPiPackageRoot(): string {
	const argvPath = process.argv[1];
	if (!argvPath) {
		throw new Error("Unable to locate the running pi command path.");
	}

	return dirname(dirname(realpathSync(argvPath)));
}

async function loadSessionManager(): Promise<{
	SessionManager: { open(path: string, sessionDir?: string): { createBranchedSession(leafId: string): string | undefined } };
}> {
	const packageRoot = getPiPackageRoot();
	const sessionManagerPath = pathToFileURL(join(packageRoot, "dist/core/session-manager.js")).href;
	return import(sessionManagerPath);
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function consumesValue(flag: string): boolean {
	return new Set([
		"--mode",
		"--provider",
		"--model",
		"--api-key",
		"--system-prompt",
		"--append-system-prompt",
		"--session-dir",
		"--models",
		"--tools",
		"-t",
		"--thinking",
		"--extension",
		"-e",
		"--link-name",
		"--skill",
		"--prompt-template",
		"--theme",
	]).has(flag);
}

function isSessionSelectionFlag(flag: string): boolean {
	return new Set([
		"--session",
		"--fork",
		"--continue",
		"-c",
		"--resume",
		"-r",
		"--no-session",
	]).has(flag);
}

function isOneShotFlag(flag: string): boolean {
	return new Set([
		"--help",
		"-h",
		"--version",
		"-v",
		"--print",
		"-p",
		"--export",
		"--list-models",
	]).has(flag);
}

function sanitizedParentArgs(args: string[]): string[] {
	const kept: string[] = [];

	for (let i = 0; i < args.length; i++) {
		const arg = args[i];

		if (arg === "--session" || arg === "--fork" || arg === "--export") {
			i++;
			continue;
		}

		if (arg.startsWith("--session=") || arg.startsWith("--fork=") || arg.startsWith("--export=")) {
			continue;
		}

		if (isSessionSelectionFlag(arg) || isOneShotFlag(arg)) {
			continue;
		}

		if (arg.startsWith("@")) {
			continue;
		}

		if (arg.startsWith("--")) {
			kept.push(arg);
			if (!arg.includes("=") && consumesValue(arg) && i + 1 < args.length) {
				kept.push(args[++i]);
			}
			continue;
		}

		if (arg.startsWith("-") && consumesValue(arg)) {
			kept.push(arg);
			if (i + 1 < args.length) {
				kept.push(args[++i]);
			}
			continue;
		}

		if (arg.startsWith("-")) {
			kept.push(arg);
		}
		// Positional startup messages are intentionally not replayed in the fork.
	}

	return kept;
}

function buildPiCommand(sessionFile: string): string {
	const argv0 = process.argv[1] ?? "pi";
	const args = [...sanitizedParentArgs(process.argv.slice(2)), "--session", sessionFile];
	return [shellQuote(argv0), ...args.map(shellQuote)].join(" ");
}

async function runTmuxSplit(command: string, cwd: string): Promise<void> {
	if (!process.env.TMUX) {
		throw new Error("Not running inside tmux; cannot create a tmux pane.");
	}

	await new Promise<void>((resolve, reject) => {
		const child = spawn("tmux", ["split-window", "-h", "-c", cwd, command], {
			stdio: "ignore",
			detached: true,
		});

		child.once("error", reject);
		child.once("exit", (code) => {
			if (code === 0) {
				resolve();
				return;
			}
			reject(new Error(`tmux split-window exited with code ${code ?? "unknown"}`));
		});
	});
}

async function fux(ctx: ExtensionCommandContext): Promise<void> {
	if (!ctx.isIdle()) {
		ctx.ui.notify("Press Escape to stop the current turn, then run /fux again.", "warning");
		return;
	}

	const currentSessionFile = ctx.sessionManager.getSessionFile();
	if (!currentSessionFile) {
		ctx.ui.notify("Cannot /fux an in-memory session. Start pi with session persistence enabled.", "warning");
		return;
	}

	if (!existsSync(currentSessionFile)) {
		ctx.ui.notify("Current session has not been written to disk yet, so there is nothing to fork.", "warning");
		return;
	}

	const leafId = ctx.sessionManager.getLeafId();
	if (!leafId) {
		ctx.ui.notify("Current session has no messages to fork yet.", "warning");
		return;
	}

	const { SessionManager } = await loadSessionManager();
	const sourceManager = SessionManager.open(currentSessionFile, ctx.sessionManager.getSessionDir());
	const forkedSessionFile = sourceManager.createBranchedSession(leafId);
	if (!forkedSessionFile) {
		ctx.ui.notify("Failed to create a persisted fork for this session.", "error");
		return;
	}

	const command = buildPiCommand(forkedSessionFile);
	await runTmuxSplit(command, ctx.cwd);
	ctx.ui.notify(`Fork opened in a new tmux pane: ${forkedSessionFile}`, "info");
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand(COMMAND_NAME, {
		description: "Fork the current session position into a new tmux pane using the same pi startup args.",
		handler: async (_args, ctx) => {
			try {
				await fux(ctx);
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`/fux failed: ${message}`, "error");
			}
		},
	});
}
