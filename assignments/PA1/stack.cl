(*
 *  CS164 Fall 94
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *  Skeleton file
 *)

class List{
   isNil() : Bool { true };

   head()  : String { { abort(); (new String); } };

   tail()  : List { { abort(); self; } };

   conc(i : String) : List {
      (new Ele).init(i, self)
   };
};

class Ele inherits List{
   front : String;
   nxt : List;

   head() : String { front };
   tail() : List { nxt };
   isNil() : Bool {false};

   init(i:String,rest:List) : List {
      {
         front <- i;
         nxt <- rest;
         self;
      }
   };
};

class StackCommand { -- generic operations
   push_num(st:List,i:String):List { (new List) };
   push_plus(st:List):List { (new List) };
   push_s(st:List):List { (new List) };
   eval(st:List):List { (new List) };
   display(st:List):Object { (new Object) };
};

class Push_num inherits StackCommand {
   push_num(st:List,i:String) :List {
      st.conc(i)
   };
};

class Push_plus inherits StackCommand{
   push_plus(st:List):List{
      st.conc("+")
   };
};

class Push_s inherits StackCommand{
   push_s(st:List) : List{
      st.conc("s")
   };
};

class Eval inherits StackCommand{

   eval(st:List) : List{
      if st.isNil()
      then st
      else
         if st.head() = "+"
         then eval_plus(st)
         else
            if st.head() = "s" 
            then eval_s(st)
            else st
            fi
         fi
      fi
   };

   eval_plus(st:List):List{
      {
         st <- st.tail();
         (let sum : Int, a : Int, b : Int in
            {
               a <- (new A2I).a2i(st.head());
               st <- st.tail();
               b <- (new A2I).a2i(st.head());
               st <- st.tail();
               sum <- a+b;
               st <- st.conc((new A2I).i2a(sum));
            }
         );
      }
   };

   eval_s(st:List):List{
      {
         st <- st.tail();
         (let a : String , b : String in
            {
               a <- st.head();
               st <- st.tail();
               b <- st.head();
               st <- st.tail();
               st <- st.conc(a);
               st <- st.conc(b);
            }
         );
      }
   };
};

class Display inherits StackCommand{
   display(st:List):Object{
      if st.isNil()
      then 0
      else {
			(new IO).out_string(st.head());
			(new IO).out_string("\n");
			display(st.tail());
		}
      fi
   };
};

class Main inherits IO {

   stk : List <- new List;

   main() : Object {
      (let op : String , cond :Bool <- true in
         while cond loop
         {
            out_string(">");
            op <- in_string();
            if op = "+"
            then stk <- (new Push_plus).push_plus(stk)
            else
               if op = "s"
               then stk <- (new Push_s).push_s(stk)
               else
                  if op = "e"
                  then stk <- (new Eval).eval(stk)
                  else
                     if op = "d"
                     then (new Display).display(stk)
                     else
                        if op = "x"
                        then cond <- false
                        else stk <- (new Push_num).push_num(stk,op)
                        fi
                     fi
                  fi
               fi
            fi;
         }
         pool
      )
   };
};
