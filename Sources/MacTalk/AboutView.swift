import SwiftUI

/// About tab: a portrait drawn in ASCII.
struct AboutView: View {
    private let portrait = #"""
%%BB%%%%%%%BBB%%%%%%%$$&8&o&omrJLc?:II,i~;+!l~_+-1]!}Qk#BBBB%%%%BBB%%%%%%%%B%%%%B%BB
B%%%%%%%%%%%%%%%%%%%@kUXn)ff)}+_~~?]!;+{i~~~I~}]+I++I!]|c*WM$%%%%%%%%%%%%%%%%%%BBB%%
B%%%%%%BB%%%%%%%B$$$Q?1-~~?Ii?[~i~i!I]|!!+?[??iI";;,,i~_l+11bB@$$%%%%%%%%%%%%%%%BBB%
%%%%%BB%%%%%%%%B&p0ci[(__i_ii,:!I^`,+}i";i?}{_-i_]_-~-{]_:I!~{jXqB$@%%%%%%%%B%%B%%%%
%%%%%%%%%%%%%@$O~i+;!i+I:`",":!I;;,,,^`^,I~_~~l~]]}-]_li+}{!I:`!?|Oa$%%%%%%%%%%%%%%B
%%%%%%%%%%%%8p0],"i-~l!;,;:;l-}[1}[_-?~iI;l;;l;IIiii__i~~!!+_lIl+;i1kB%%%%%%%%%%%%%%
%%%%%%%%%%%%B(;I;;;;,:;l~+l!{t[~_?1!+1}}?][}{|))/nuuxnx|{]-~I;"""?xfJ$8%%%%%%%%%%%%%
%%%%%%%%%%%8%C(!,Iiiil;;+--?-[[]-/t(+?(1/YOpkoa**oo**abpwmQz|~"^:?uLM%%%%%%%%%%%%%%%
%%%%%%%%8888BZ-""I;l_!;I;+?+~}1?{]}|?_{]|wW%%%8%%%8&&WWM*ahbqLx_`(QO&88%%%%%%%%%%%%%
%%%%%%%8%%B&x-:",,"",::"l_ll??(11)_i[[[xrzk&&8%%88&WWM#**oakdbqL[Lb*%888888%8%88%88%
8888888%&#kQ!,"""^"""""",I!~??1(/zcf/(|{utn*WBBB%8&&&&&&&W*okddqw&%%8888888888888888
8888888*dJz(!^""""""""","?+l!!?--nvt||/?ccYW&8%%%BB%8WMoo#MM*hkkwhB&8888888888888888
&&&&&&8oJLUv~^"""""""",,:?i,;I~_]11~{1tOba&&&&8%%8MabmZCcvcLqahkpuY%&&&&&&&&&&&&&&&&
&&&&&&W&CwC+^"""""""",:"^;,!)t_1}l__{Xo&MWMW&&&W#oo**obpJXUJOkhZx1O8W&&&&&&&&&&&&&&&
WWWWWWWW*WvlI""""^";"^';~-,:)}_/?+ttrwoMW&8&8&MokpmQZqL?-(XpM%%YitMWWWWWWWWWWWWWWWWW
WWWWWWWWW&Y',^^"""",^:tYJLQUv]?[11tLr0hMW&8%B%&#hddwwdmtfXo&&B$#1xaMWWWWWWWWWWWWWWWW
WWWMWWWMMMk|+!,^""""^vpmbOCdMbLjft/cz0aM#W&%@@@B888WaqQJYmM%8%@$Mk&MMMWMMMMMMMWWWWMM
MMMMMMMMWpvZut1I^""^:mq*BMwjOkokOuxcCma**#M&%@@@@B%&MabpkM%B@@%%B#aMMMMMMMMMMMMMMMMM
MMMMMM##Wq(1",-I:"","CpopZOCY#&obOCZmboooa*M&8%B@@%8WMMWW&%@B8WW%@Wo*M#MMMMMMM######
#########a[;lli,I,^"^]wpk%%aUqBMaQCOZpkhhaoo#MW&&88%%8%&W#*MM&8WMW%Mda##############
********#m}__i,^,:;;"`1p#&M#dLohpQcCCOqkhhaa*#MWMW&&&&&W#hadmw0JXnJQmo**************
*******o*oJ)[~;li!I;^"'_Yw*%B$&qQUcuvUCppkhao*MMMWW&&&WMo#%8hCUJJf/h****************
ooooooooo*oLc/~l:"""""""I+(xvcfnCxjfxxCdqkkka**MMWWWWWWMWkO0Ln}[[|[coooooooooooooooo
oooooooooooobOu{:""",",_[]]]}/xuu//1[xZOZmmZdppo##MMMM#aJ|[)nv||}j[(aooooooooooooooo
oaaooaoaaaaa*C/!I,^""^!{(tnXJCCcf{?-(juXJJUUmmqw0dka*odc}(jvXUUzv)iY*aooooaaooaaaooo
aaaaaaaaaaah*O+,'^""""?|fnzCOZQz(+~_?)/ttunnLCQZ0YUwkkO|rqbkpZJcurthaaaaaaaaaaaaaaaa
hhaaahhhhhhhhaU(1~""""}rxvYQZwmLf-~I!++_?)(1(xYQYxUddOjfCOpUYf--?}Cohhhhhhaahhhhhhhh
hhhhhhhhhhhhhhadO],"^;)rvzCOmwwmJ/l,:;IiIii~-|zt1xULYt}t)rcXJr}?-[Xakhhhhhhhhhhhhhhh
kkkkkkkkkkkkkkkhkZCUY||xcYCOmwqwOY|_I:,:,;I;I_}}]{1))]1]?|1xn(}({[-Zakkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkbkhaaaufncXJQOmwmZ0Czf{_ll!:,,I;I:I;I;llli~~_][--_?-rbkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkbbbbbaC/nccXJLOZmmmZ0LYcnt)1]+!l,"^"",""^"",:I+~I,i?])Okbkbbbkbbkkkkkk
bbbbbbbbbbbbbbkhkkb0jxnXXYCL0ZmwwmmOQCJUYYvj(1?+iI:,,l,^'`^"",:;Il?npbbbbbbbbbbbbbbb
ddbddddddpdbkhm0OQvtnXXYYUCLQ0Zwwwwmm00LLQ0LUvj1?+i!-JwOXj}+i!il_tUpbdddbbbddddddbbb
dddddppbhhkpC((xcXczcYUJCCLLL0ZwqqqwwOQJJJL0CXt]+iii~l(JZkahbwZZpkkbdddddddddddddddd
ppppdkkwYf}-I"]QqZCCCJJLLQQLQOmmqqppqwmOQLJYn|}[]-+ii;.'^l(c0phakpppppddddpddddddddd
dbkbwU(i,",:Il:lrwdm0L000OO000OmqpppqwwmZ0Uuftff/1]~i;"""`''"![rQpkkkdpqpppppppppppp
mJj[i:":I;II;;I;"irZdwmZZmm0QQOZwpddppqwZQCUYXXzn/{]_:^""""""`'',~1rXOpkbpqqqqqqqqpp
i;",:;II;;;;II;;I:"l)XmkkbqZ0QL0ZqqqmmOQCJUUL00Jvfj(!^"""""""""",^``"I-fUZpbdpqqqqqq
:;;IIIII;I;;;IIIIII;""i)zmkkdwO0ZwqwOLJYXYJOqpmCzx};^"""""""""""",::;:,",!]rYOqbdpqw
;;;;IIIII;;;;IIIlIIIII:^^;_)nYLQZdhhdmO0OqkakZu)?I^",""""""""""",,,::;;;;:,,:l?tYZdd
;;;;IIII;;;;IIIIIIIIIIllI;,^^,;!+[(/tffjj/(}_l,"":;;::,,,,,",,,,,:::;;;;;;III;:,:i1v
;IIIIIII;;II;;IIIIIIIlIllllllI;:,"^"",,,,"^"":;III;;;;:;;;::::::::::;;;;;;;IIIIII;,;
IIIIIIIIIIIIIIIIIIIIIIIIIIIIllIIIIIIIIII;;;IIIIIIII;;;;;;;;;;;;;;;;;;;;III;IIIIIIIl;
^:IIIIIIIIIIIIIIIIllllIIIIIIIIIIIIIllIIlIIIIlIIIIIIIIIIII;II;;;;;;;;;I;III;;IIIII,`
  ',;lIIIIIIIIIIllIIIIIIIIIIlllIIIIIlIlIlllIllllIIIIIIIIIIIIII;II;;;;I;;II;;II;"'
    .^:IIIIIIIIIIlIIIIIIIIlIllIllIIIIIIIIIllIIIIIlIIIIIIIIIIIIIIIIIII;;;III;,`
       .^:IllIIIIIIIlIlIIlIIlllIIlIlIIIIIIIIIlIIIIIIIIIIlIIIIIIIIIIIIIIII:`.
          .`,;IllIIIIIIIIlIllllIIIlIIIIIIIIIIIIIIIlllIlllIIIIIIIIIllI;"`.
              '^,;IllllIIIIllIIIIIlIIIIIIIIIIIIIIIIIllllIllIllllI;"`.
                  .'^,:;lllllllIIIIIIIIII;;;IIlllIIIllllllI;:,^'.
                        .`^",:;IIIIIIIII;;;IIlllIII;;:,"^'.
"""#

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("About")
                .font(.system(size: 26, weight: .semibold))

            Text(portrait)
                .font(.system(size: 7, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(0)
                .fixedSize()
                .textSelection(.disabled)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .center, spacing: 4) {
                Text("MacTalk \(appVersion)")
                    .font(.system(size: 13, weight: .medium))
                Text("Made by Niko da Toolzz")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(36)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }
}
