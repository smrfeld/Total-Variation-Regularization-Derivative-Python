(* ::Package:: *)

(* ::Title:: *)
(*Differentiate with Total Variation Regularization (TVR)*)


BeginPackage["diffTVR`"]


getDiffTVR::usage="getDiffTVR[data,derivGuess,noOptSteps,dx,alpha,returnOptions=<||>] takes noOptStep optimization steps to compute
the TVR derivative.
If returnProgress=<||>:
   There is one return value: the final derivative.
If returnProgress=<|progress->True|>:
   There are two return values: the final derivative and a list of the derivatives during the iteration.
If returnProgress=<|progress->False, interval->10|>
   There are two return values: the final derivative and the derivatives during the optimizations at the specified interval."


getDiffTVRGivenStructs::usage="getDiffTVRGivenStructs[data,derivGuess,noOptSteps,structsTVR,returnOptions=<||>] as getDiffTVR,
but using the structs from the makeTVRstructs command."


getDiffTVRupdate::usage="getDiffTVRupdate[data,derivCurr,dx,alpha] takes a single step 
of the TVR differentiation and returns the update."


getDiffTVRupdateGivenStructs::usage="getDiffTVRupdateGivenStructs[data,derivCurr,structsTVR] takes a single step 
of the TVR differentiation and returns the update, given the structs from the makeTVRstructs command."


makeTVRstructs::usage="makeTVRstructs[n,dx,alpha] makes and returns the necessary TVR structs."


(* ::Subtitle:: *)
(*Private*)


Begin["`Private`"]


(* n x n+1 *)
makeDmat[n_,dx_]:=Table[
Table[
If[i==j,-1,If[i==j-1,1,0]]
,{j,n+1}]
,{i,n}]/dx;


(* nxn+1*)
makeAmat[n_,dx_]:=Table[
Table[
If[i==1,0,
If[j==1,0.5,
If[j<i,1,
If[i==j,1-0.5,
0]]]
]
,{j,n+1}]
,{i,n+1}][[2;;]]*dx;


(* ::Input::Initialization:: *)
makeAmatTsumtbl[n_]:=Table[Table[1,{j,n}],{i,n+1}];


(* ::Input::Initialization:: *)
makeAmatTcumtbl[n_]:=Table[Table[
If[j<=i,1,0]
,{j,n}],{i,n}]


(* ::Input::Initialization:: *)
makeAmatTdiagtbl[n_]:=0.5*IdentityMatrix[n]


(* ::Input::Initialization:: *)
makeAmatTcomb[n_]:=Prepend[
makeAmatTcumtbl[n]-makeAmatTdiagtbl[n],
ConstantArray[0.5,n]
]


(* ::Input::Initialization:: *)
(* n+1xn *)
makeAmatT[n_,dx_]:=(makeAmatTsumtbl[n]-makeAmatTcomb[n])*dx;


(* ::Input::Initialization:: *)
(* n x n *)
makeEnMat[dmat_,un_]:=DiagonalMatrix[1.0/Sqrt[(dmat . un)^2+10^-6]]


(* ::Input::Initialization:: *)
(* n+1 x n+1 *)
makeLnMat[dx_,dmat_,enmat_]:=dx*Transpose[dmat] . enmat . dmat;


(* ::Input::Initialization:: *)
makeGnVec[amat_,amatT_,data_,alpha_,un_,lnmat_]:=amatT . amat . un-amatT . (data-data[[1]])+alpha*lnmat . un;


(* ::Input::Initialization:: *)
makeHnMat[alpha_,amat_,amatT_,lnmat_]:=amatT . amat+alpha*lnmat;


makeTVRstructs[n_,dx_,alpha_]:=Module[
{structsTVR}
,
structsTVR=Association[];

structsTVR["n"]=n;
structsTVR["dx"]=dx;
structsTVR["alpha"]=alpha;

structsTVR["dmat"]=makeDmat[n,dx];
structsTVR["amat"]=makeAmat[n,dx];
structsTVR["amatT"]=makeAmatT[n,dx];

Return[structsTVR]
]


(* ::Input::Initialization:: *)
getDiffTVRupdate[data_,derivCurr_,dx_,alpha_]:=Module[
{n,structsTVR}
,
n=Length[data];
structsTVR=makeTVRstructs[n,dx,alpha];

Return[getDiffTVRupdateGivenStructs[data,derivCurr,structsTVR]];
]


getDiffTVRupdateGivenStructs[data_,derivCurr_,structsTVR_]:=Module[
{enmat,lnmat,hnmat,gnvec,update}
,
enmat=makeEnMat[structsTVR["dmat"],derivCurr];
lnmat=makeLnMat[structsTVR["dx"],structsTVR["dmat"],enmat];
hnmat=makeHnMat[structsTVR["alpha"],structsTVR["amat"],structsTVR["amatT"],lnmat];
gnvec=makeGnVec[structsTVR["amat"],structsTVR["amatT"],data,structsTVR["alpha"],derivCurr,lnmat];
update=LinearSolve[hnmat,-gnvec];

Return[update]
]


getDiffTVR[data_,derivGuess_,noOptSteps_,dx_,alpha_,returnOptions_:<||>]:=Module[
{n,structsTVR}
,
n=Length[data];
structsTVR=makeTVRstructs[n,dx,alpha];

Return[getDiffTVRGivenStructs[data,derivGuess,noOptSteps,structsTVR,returnOptions]]
]


getDiffTVRGivenStructs[data_,derivGuess_,noOptSteps_,structsTVR_,returnOptions_:<||>]:=Module[
{derivSt,update,derivCurr,interval,progress}
,
If[
	KeyExistsQ[returnOptions,"interval"],
	interval=returnOptions["interval"],
	interval=1
];
If[
	KeyExistsQ[returnOptions,"progress"],
	progress=returnOptions["progress"],
	progress=False
];
derivCurr=derivGuess;
derivSt={derivCurr};

Monitor[
	Do[
		update = getDiffTVRupdateGivenStructs[data,derivCurr,structsTVR];
		derivCurr += update;
		
		If[progress,
			If[Mod[optStep,interval]==0,
				AppendTo[derivSt,derivCurr];
			];
		];
		
	,{optStep,noOptSteps}];
,ProgressIndicator[optStep,{1,noOptSteps}]];

If[progress,
	Return[{derivCurr,derivSt}],
	Return[derivCurr]
]
]


End[];


EndPackage[];
