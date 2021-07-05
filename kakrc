source "%val{config}/plugins/plug.kak/rc/plug.kak"

plug "andreyorst/plug.kak" noload

plug "raiguard/one.kak" theme config %{
	colorscheme one-dark
}

plug "https://git.tchncs.de/notramo/elvish.kak"

hook global WinSetOption filetype=nim %{
	set-option window tabstop 2
	set-option window indentwidth 2
}

hook global WinSetOption filetype=go %{
	set-option window tabstop 4
	set-option window indentwidth 0
}

hook global WinSetOption filetype=python %{
	set-option window tabstop 4
	set-option window indentwidth 4
}

hook global WinSetOption filetype=json %{
	set-option buffer formatcmd jq
}

plug "andreyorst/smarttab.kak" defer smarttab %{
	set-option global softtabstop 2
} config %{
	hook global WinSetOption filetype=(elvish|nim|python) expandtab
	#hook global WinSetOption filetype=(makefile|gas) noexpandtab
	#hook global WinSetOption filetype=(c|cpp) smarttab
} 

plug "kak-lsp/kak-lsp" config %{
	# Uncomment to debug LSP
	#eval %sh{echo ${kak_opt_lsp_cmd} >> /tmp/kak-lsp.log}
	#set-option global lsp_cmd "kak-lsp -s %val{session} -vvv --log /tmp/kak-lsp.log"

	hook global WinSetOption filetype=(go|rust|python) %{
		lsp-enable-window
		lsp-auto-hover-enable

		hook window BufWritePre .* lsp-formatting-sync

		map global user l %{: enter-user-mode lsp<ret>} -docstring "LSP mode"
	}
}

plug "alexherbo2/alacritty.kak" %{
	alacritty-integration-enable
}

plug "lePerdu/kakboard" %{
	hook global WinCreate .* %{ kakboard-enable }
}

hook global WinCreate ^[^*]+$ %{
    add-highlighter window/ number-lines -hlcursor
}

hook global RegisterModified 'y' %{ nop %sh{
	printf %s "$kak_main_reg_dquote" | xclip -in -selection clipboard >&- 2>&-
}}

define-command -params 1.. run %{
	evaluate-commands %sh{
		output="$(mktemp -d -t kak-run-XXXXXXXX)/fifo"
		mkfifo "${output}"

		case "$1" in
			*.go)
				{ go run "${1}" "${@:2}" > "${output}"; } > /dev/null 2>&1 < /dev/null &
			;;
			*)
				echo "No runner configured" >&2
				exit
		esac

		pid="$!"

		# Ensure that there are never duplicate buffer names
		tmp="${output//*-/}"
		tmp="${tmp//\/*/}"

		echo "edit! -fifo ${output} -scroll -readonly *run-${tmp}*"
		echo "hook buffer BufClose .* %{ nop %sh{ kill ${pid} && rm -r $(dirname ${output})} }"
	}
}
