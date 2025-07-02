" vim -b : edit binary using xxd-format!
augroup Binary
    autocmd!
    autocmd BufReadPre  *.bin set binary
    autocmd BufReadPost *.bin
                \ if &binary
                \ |   execute "silent %!xxd -c 32"
                \ |   set filetype=xxd
                \ |   redraw
                \ | endif
    autocmd BufWritePre *.bin
                \ if &binary
                \ |   let s:view = winsaveview()
                \ |   execute "silent %!xxd -r -c 32"
                \ | endif
    autocmd BufWritePost *.bin
                \ if &binary
                \ |   execute "silent %!xxd -c 32"
                \ |   set nomodified
                \ |   call winrestview(s:view)
                \ |   redraw
                \ | endif
augroup END
