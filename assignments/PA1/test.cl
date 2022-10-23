class Main inherits IO{

    main() : Object {
        (let i : Int in     
        {
            i <- (new A2I).a2i("-1");
            i <- (~2)*i;
            out_int(i);
            out_string("\n");           
        }
        )
    };

};
