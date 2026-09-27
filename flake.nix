{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    let
                        implementation =
                            { lib , pkgs , ... } :
                                {
                                    options.node-packages =
                                        {
                                            default =
                                                package :
                                                    pkgs.runShellCommand
                                                        "node-package"
                                                        {
                                                            pkgs =
                                                                [
                                                                    (
                                                                        pkgs.writeShellApplication
                                                                            {
                                                                                name = "node-package" ;
                                                                                runtimeInputs = [ pkgs.node ] ;
                                                                                text =
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        mkdir --parents "$OUT"
                                                                                        cd "$OUT"
                                                                                        ln --symbolic ${ builtins.toFile "package.json" ( builtins.toJSON package ) } > "$OUT/package.json"
                                                                                        npm install
                                                                                    '' ;
                                                                            }
                                                                    )
                                                                ] ;
                                                        }
                                                        ''"node-package "$out"'' ;
                                            type = lib.types.functionTo lib.types.package ;
                                        } ;
                                } ;
                        in
                            {
                                implementation = implementation ;
                            } ;
            } ;
}