destination = Path.join([:code.priv_dir(:who_owns_what), "static", "images", "networks"])
System.cmd("rm", ["-r", destination])
System.cmd("mkdir", ["-p", destination])
System.cmd("cp", ["-r", "./../images/networks-svg/.", destination])
