{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { failure } :
                        let
                            implementation =
                                { config , lib , pkgs , ... } :
                                    {
                                        options.node-package =
                                            {
                                                build =
                                                    lib.mkOption
                                                        {
                                                            default =
                                                                input :
                                                                    pkgs.runCommand
                                                                        "build"
                                                                        {
                                                                            nativeBuildInputs =
                                                                                [
                                                                                    (
                                                                                        pkgs.writeShellApplication
                                                                                            {
                                                                                                name = "build" ;
                                                                                                runtimeInputs =
                                                                                                    [
                                                                                                        pkgs.coreutils
                                                                                                        pkgs.findutils
                                                                                                        pkgs.nodejs
                                                                                                        (
                                                                                                            pkgs.writeShellApplication
                                                                                                                {
                                                                                                                    name = "implode" ;
                                                                                                                    runtimeInputs =
                                                                                                                        [
                                                                                                                            pkgs.coreutils
                                                                                                                            pkgs.findutils
                                                                                                                            pkgs.jq
                                                                                                                            ( failure 3714882433516143 )
                                                                                                                        ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            RELATIVE_INPUT_FILE="$1"
                                                                                                                            OUT="$2"
                                                                                                                            PERMISSIONS="$( jq --raw-output ".permissions" "$RELATIVE_INPUT_FILE/metadata.json" )" || failure 3808418135747408
                                                                                                                            TAG="$( jq --raw-output ".tag" "$RELATIVE_INPUT_FILE/metadata.json" )" || failure 2878641484898157
                                                                                                                            TYPE="$( jq --raw-output ".type" "$RELATIVE_INPUT_FILE/metadata.json" )" || failure 1111350995632152
                                                                                                                            RELATIVE_OUTPUT_FILE="$OUT/node_modules/$TAG"
                                                                                                                            RELATIVE_OUTPUT_DIRECTORY="$( dirname "$RELATIVE_OUTPUT_FILE" )" || failure 9352183167901733
                                                                                                                            mkdir --parents "$RELATIVE_OUTPUT_DIRECTORY"
                                                                                                                            if [[ "$TYPE" == "directory" ]]
                                                                                                                            then
                                                                                                                                mkdir --parents "$RELATIVE_OUTPUT_FILE"
                                                                                                                            elif [[ "$TYPE" == "regular file" ]]
                                                                                                                            then
                                                                                                                                cat "$TAG"/parts/* > "$RELATIVE_OUTPUT_FILE"
                                                                                                                            else
                                                                                                                                failure 1129645981666929 "$RELATIVE_INPUT_FILE" "$PERMISSIONS" "$TAG" "$TYPE"
                                                                                                                            fi
                                                                                                                            chmod "$PERMISSIONS" "$RELATIVE_OUTPUT_FILE"
                                                                                                                        '' ;
                                                                                                                }
                                                                                                        )
                                                                                                    ] ;
                                                                                                text =
                                                                                                    ''
                                                                                                        OUT="$1"
                                                                                                        mkdir --parents "$OUT"
                                                                                                        cat ${ builtins.toString input }/package.json > "$OUT/package.json"
                                                                                                        cd ${ builtins.toString input }
                                                                                                        find node_modules.exploded -mindepth 1 -maxdepth 1 -exec implode {} "$OUT" \;
                                                                                                    '' ;
                                                                                            }
                                                                                    )
                                                                                ] ;
                                                                            }
                                                                            ''
                                                                                build "$out"
                                                                            '' ;
                                                            type = lib.types.functionTo lib.types.package ;
                                                        } ;
                                                execute =
                                                    lib.mkOption
                                                        {
                                                            default =
                                                                { command , name , package } :
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = name ;
                                                                            runtimeInputs = [ pkgs.nodejs ] ;
                                                                            text =
                                                                                ''
                                                                                    cd ${ package }
                                                                                    npm ${ command }
                                                                                '' ;
                                                                        } ;
                                                            type = lib.types.functionTo lib.types.package ;
                                                        } ;
                                                fetch =
                                                    lib.mkOption
                                                        {
                                                            default =
                                                                package :
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "fetch" ;
                                                                            runtimeInputs =
                                                                                [
                                                                                    pkgs.coreutils
                                                                                    pkgs.git
                                                                                    pkgs.nodejs
                                                                                    (
                                                                                        pkgs.writeShellApplication
                                                                                            {
                                                                                                name = "explode" ;
                                                                                                runtimeInputs =
                                                                                                    [
                                                                                                        pkgs.coreutils
                                                                                                        pkgs.git
                                                                                                        pkgs.jq
                                                                                                        ( failure 5896253285267998 )
                                                                                                    ] ;
                                                                                                text =
                                                                                                    ''
                                                                                                        RELATIVE_INPUT_FILE="$1"
                                                                                                        ABSOLUTE_INPUT_FILE="$( realpath "$RELATIVE_INPUT_FILE" )" || failure 7861779372817123
                                                                                                        TAG="${ "$" }{RELATIVE_INPUT_FILE#node_modules/}"
                                                                                                        HASH="$( echo "$TAG" | sha512sum | cut --characters 1-128 )" || failure 3652604998111458
                                                                                                        RELATIVE_OUTPUT_FILE="node_modules.exploded/$HASH"
                                                                                                        PERMISSIONS="$( stat --printf %a "$ABSOLUTE_INPUT_FILE" )" || failure 9035064744130892
                                                                                                        TYPE="$( stat --printf %F "$ABSOLUTE_INPUT_FILE" )" || failure 9216061067032392
                                                                                                        if [[ -d "$RELATIVE_OUTPUT_FILE" ]]
                                                                                                        then
                                                                                                            failure 0701446510561736 "$HASH" "$PERMISSIONS" "$TAG" "$TYPE"
                                                                                                        else
                                                                                                            mkdir --parents "$RELATIVE_OUTPUT_FILE"
                                                                                                        fi
                                                                                                        cd "$RELATIVE_OUTPUT_FILE"
                                                                                                        jq \
                                                                                                            --null-input \
                                                                                                            --arg PERMISSIONS "$PERMISSIONS" \
                                                                                                            --arg TAG "$TAG" \
                                                                                                            --arg TYPE "$TYPE" \
                                                                                                            '{
                                                                                                                "permissions" : $PERMISSIONS ,
                                                                                                                "tag" : $TAG ,
                                                                                                                "type" : $TYPE
                                                                                                            }' > metadata.json
                                                                                                        if [[ -d "$ABSOLUTE_INPUT_FILE" ]]
                                                                                                        then
                                                                                                            :
                                                                                                        elif [[ -f "$ABSOLUTE_INPUT_FILE" ]]
                                                                                                        then
                                                                                                            mkdir parts
                                                                                                            cd parts
                                                                                                            split --bytes 1M "$ABSOLUTE_INPUT_FILE"
                                                                                                        else
                                                                                                            failure 9059723240083957 "$ABSOLUTE_INPUT_FILE" "$PERMISSIONS" "$TAG" "$TYPE"
                                                                                                        fi
                                                                                                        git add .
                                                                                                    '' ;
                                                                                            }
                                                                                    )
                                                                                ] ;
                                                                            text =
                                                                                ''
                                                                                    MESSAGE="$1"
                                                                                    cat ${ builtins.toFile "package.json" ( builtins.toJSON package ) } > "package.json"
                                                                                    git add package.json
                                                                                    npm install
                                                                                    find node_modules -exec explode {} \;
                                                                                    git clean -fd
                                                                                    git commit -m "$MESSAGE" --allow-empty --allow-empty-message
                                                                                '' ;
                                                                        } ;
                                                            type = lib.types.functionTo lib.types.package ;
                                                        } ;
                                            } ;
                                    } ;
                            in
                                {
                                    implementation = implementation ;
                                } ;
            } ;
}