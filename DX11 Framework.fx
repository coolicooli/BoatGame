//--------------------------------------------------------------------------------------
// File: DX11 Framework.fx
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------

Texture2D txDiffuse : register(t0);
SamplerState samLinear : register(s0);

cbuffer ConstantBuffer : register( b0 )
{
	matrix World;
	matrix View;
	matrix Projection;
    
	float4 DiffuseMtrl;
	float4 DiffuseLight;
	float3 LightVecW;
	float padding;

	float4 AmbientMtrl;
	float4 AmbientLight;

	float4 SpecularMtrl;
	float4 SpecularLight;

	float SpecularPower;
	float3 EyePosW; 	// Camera position in world space
    
    float gTime;
    

}

//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
	float4 Pos : SV_POSITION;
	float3 Norm : NORMAL;
	float3 PosW : POSITION;
	float4 Color : COLOR0;
    float2 Tex : TEXCOORD0;
};

//------------------------------------------------------------------------------------
// Vertex Shader - Implements Gouraud Shading using Diffuse lighting only
//------------------------------------------------------------------------------------
VS_OUTPUT VS(float4 Pos : POSITION, float3 NormalL : NORMAL, float2 Tex : TEXCOORD0)
{
	VS_OUTPUT output = (VS_OUTPUT)0;

	output.Pos = mul(Pos, World);
	output.PosW = EyePosW - output.Pos.xyz;
	output.Pos = mul(output.Pos, View);
	output.Pos = mul(output.Pos, Projection);
	output.Norm = NormalL;
    output.Tex = Tex;
	
	return output;
}


VS_OUTPUT VSWave(float4 Pos : POSITION, float3 NormalL : NORMAL, float2 Tex : TEXCOORD0)
{
    
    Pos.xyz += 0.1f * sin(Pos.x)  * sin(Pos.z) * sin(gTime * 0.4);

    
    VS_OUTPUT output = (VS_OUTPUT) 0;

    output.Pos = mul(Pos, World);
    output.PosW = EyePosW - output.Pos.xyz;
    output.Pos = mul(output.Pos, View);
    output.Pos = mul(output.Pos, Projection);
    output.Norm = NormalL;
    output.Tex = Tex;
	
    return output;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS(VS_OUTPUT input, float2 Tex : TEXCOORD0) : SV_Target
{


	float3 normalW = mul(float4(input.Norm, 0.0f), World).xyz;
	normalW = normalize(normalW);

	float3 toEye = normalize(input.Pos.xyz);
	float3 r = reflect(-LightVecW, normalW);

	float diffuseAmount = max(dot(LightVecW, normalW), 0.0f);
	float specularAmount = pow(max(dot(r, toEye), 0.0f), SpecularPower);

	float3 ambient = AmbientMtrl * AmbientLight;
	float3 diffuse = diffuseAmount * (DiffuseMtrl * DiffuseLight).rgb;
	float3 specular = specularAmount * (SpecularMtrl * SpecularLight).rgb;
    float3 textureColour = txDiffuse.Sample(samLinear, input.Tex);

    input.Color.rgb = (diffuse + ambient + specular) * textureColour;
	input.Color.a = DiffuseMtrl.a;

    return input.Color;
}