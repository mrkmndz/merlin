let (^/) = Filename.concat

let gen_rule dir file =
  let path = dir ^/ file in
  let enabled_if =
    let ic = open_in path in
    let line =
      try input_line ic
      with End_of_file -> ""
    in
    if Std.String.is_prefixed line ~by:"(enabled_if" then
      line
    else
      ""
  in
  Printf.printf {|
(alias
 (name runtest)%s
 (deps (:t %s)
       (source_tree %s)
       %%{bin:ocamlmerlin}
       %%{bin:ocamlmerlin-server})
 (action
   (chdir %s
     (setenv MERLIN %%{exe:merlin-wrapper}
     (setenv OCAMLC %%{ocamlc}
       (progn
         (run %%{bin:mdx} test --syntax=cram %%{t})
         (diff? %%{t} %%{t}.corrected)))))))
|} enabled_if path dir dir

let rec scan_fs dir =
  let content =
    try Sys.readdir dir
    with Sys_error _ -> [||]
  in
  Array.iter (fun file ->
    let path = dir ^/ file in
    if Sys.is_directory path then
      scan_fs path
    else if Filename.check_suffix file ".t" then
      gen_rule dir file
  ) content

let () =
  scan_fs ".";
  flush_all ();
  exit 0
