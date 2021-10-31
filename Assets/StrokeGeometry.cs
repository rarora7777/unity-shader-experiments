using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class StrokeGeometry : MonoBehaviour
{
    // Start is called before the first frame update

    MeshFilter mf;
    Material mat;
    
    public Vector3[] verts;
    public enum StrokeType { Plane = 0, Sphere = 1};
    public StrokeType strokeType;
    public float strokeWidth = 0.02f;
    public bool drawConnections = false;
    public float circleRadius = 1.0f;
    public Vector3 circleOrigin = new Vector3(1.0f, 1.0f, 2.0f);

    private struct ShaderPropertyIDs
    {
        public int _StrokeType;
        public int _StrokeWidth;
        public int _DrawConn;
    }
    private ShaderPropertyIDs shaderPropIds;


    void Start()
    {
        mat = GetComponent<MeshRenderer>().material;
        GetComponent<MeshRenderer>().material = mat;
        mf = GetComponent<MeshFilter>();
        mf.sharedMesh = new Mesh();

        shaderPropIds = new ShaderPropertyIDs()
        {
            _StrokeType = Shader.PropertyToID("_StrokeType"),
            _StrokeWidth = Shader.PropertyToID("_StrokeWidth"),
            _DrawConn = Shader.PropertyToID("_DrawConn"),
        };

        mat.SetInt(shaderPropIds._StrokeType, (int)strokeType);
        mat.SetFloat(shaderPropIds._StrokeWidth, strokeWidth);
        mat.SetInt(shaderPropIds._DrawConn, drawConnections ? 1 : 0);
    }

    // Update is called once per frame
    void Update()
    {
        CreateVertices(circleOrigin, circleRadius);

        var mesh = mf.sharedMesh;

        mesh.vertices = verts;
        int[] tris = new int[3 * (verts.Length - 1)];
        for(int i=0; i<verts.Length-1; ++i)
        {
            tris[3 * i + 0] = i;
            tris[3 * i + 1] = i + 1;
            tris[3 * i + 2] = i + 1;
        }
        mesh.triangles = tris;

        mat.SetInt(shaderPropIds._StrokeType, (int)strokeType);
        mat.SetFloat(shaderPropIds._StrokeWidth, strokeWidth);
        mat.SetInt(shaderPropIds._DrawConn, drawConnections ? 1 : 0);
    }

    void CreateVertices(Vector3 origin, float radius)
    {
        int n = 100;
        float fn = n;
        verts = new Vector3[n + 1];
        for (int i = 0; i < verts.Length; ++i)
        {

            verts[i] = origin + radius * new Vector3(
                Mathf.Cos(2.0f * Mathf.PI * i / fn),
                2.0f,
                Mathf.Sin(2.0f * Mathf.PI * i / fn));
        }
    }
}
