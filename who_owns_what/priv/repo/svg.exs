destination = Path.join([:code.priv_dir(:who_owns_what), "static", "images", "networks"])
System.cmd("cp", ["-r", "./../images/networks-svg/.", destination])
